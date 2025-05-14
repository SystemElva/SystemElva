const std = @import("std");

const Self = @This();

partitioning_scheme: PartitioningScheme,
partitions: []Partition,
action: Action,

pub const ParserError = error{
    FileReadError,
    InvalidJsonString,
    InvalidPath,
    InvalidVersion,
    InvalidAction,
    InvalidPartitionArray,
    InvalidPartitionArrayItem,
    InvalidPartitionName,
    InvalidPartitionLength,
    InvalidPartitionFillerByte,
    InvalidPartitionBackingFile,
    InvalidContentType,
};

pub const PartitioningScheme = enum(u8) {
    master_boot_record,
    guid_partition_table,
};

pub const FilesystemCreationInfo = struct {
    filesystem: enum(u16) {
        fat12,
    } = .fat12,
    label: []u8 = "",
    logical_sector_size: usize = 512,
    cluster_size: usize = 8,
    allocation_structure_count: usize = 2,
    allocation_structure_size: usize = 4,
};

pub const Partition = struct {
    pub const ContentType = enum {
        copy_file,
        fill_byte,
        create_fs,

        fn fromString(content: []const u8) ParserError!ContentType {
            if (std.mem.eql(u8, content, "copy_file")) {
                return .copy_file;
            }
            if (std.mem.eql(u8, content, "fill_byte")) {
                return .fill_byte;
            }
            if (std.mem.eql(u8, content, "create_fs")) {
                return .create_fs;
            }
            return ParserError.InvalidContentType;
        }
    };

    pub const Content = struct {
        type: ContentType,
        copy_file: []u8 = "", // file's name
        fill_byte: u8 = 0, // literal value
        create_fs: FilesystemCreationInfo = .{},
    };

    index: usize,
    name: []u8,
    length: usize,

    content: Content,

    /// This function works best with an arena allocator.
    pub fn fromJson(
        path: []u8,
        json_value: std.json.Value,
        sequential_index: usize,
        allocator: std.mem.Allocator,
    ) !Partition {
        if (json_value != .object) {
            return ParserError.InvalidPartitionArrayItem;
        }

        // > Read JSON Values

        const json = json_value.object;

        // >> Name (internal identifier / program's preferred display name)

        const unchecked_name = json.get("name");
        if (unchecked_name == null) {
            return ParserError.InvalidPartitionName;
        }
        if (unchecked_name.? != .string) {
            return ParserError.InvalidPartitionName;
        }
        const name = try allocator.dupe(
            u8,
            unchecked_name.?.string,
        );

        // >> Length (in logical sectors)

        const unchecked_length = json.get("length");
        if (unchecked_length == null) {
            return ParserError.InvalidPartitionLength;
        }
        if (unchecked_length.? != .integer) {
            return ParserError.InvalidPartitionLength;
        }
        const length = unchecked_length.?.integer;

        // >> Content Type (copy_file / fill_byte / create_fs)

        const unchecked_content_type = json.get("content");
        if (unchecked_content_type == null) {
            return ParserError.InvalidContentType;
        }
        const content_type = try ContentType.fromString(
            unchecked_content_type.?.string,
        );

        // >> Content Type-specific Values

        var content: Content = .{
            .type = content_type,
        };

        switch (content_type) {
            .fill_byte => {
                const unchecked_byte = json.get("byte");
                if (unchecked_byte != null) {
                    if (unchecked_byte.? != .integer) {
                        return ParserError.InvalidPartitionFillerByte;
                    }
                    const byte = unchecked_byte.?.integer;
                    if (byte < 0) {
                        return ParserError.InvalidPartitionFillerByte;
                    }
                    if (byte > 255) {
                        return ParserError.InvalidPartitionFillerByte;
                    }
                    content.fill_byte = @intCast(byte);
                }
            },

            .copy_file => {
                const unchecked_file_path = json.get("file");
                if (unchecked_file_path == null) {
                    return ParserError.InvalidPartitionBackingFile;
                }
                if (unchecked_file_path.? != .string) {
                    return ParserError.InvalidPartitionBackingFile;
                }
                const raw_string = unchecked_file_path.?.string;
                const paths: [2][]const u8 = .{ path, raw_string };
                content.copy_file = try std.fs.path.join(allocator, &paths);
            },

            .create_fs => {
                @panic("create_fs isn't implemented yet.");
            },
        }

        return .{
            .index = sequential_index,
            .name = name,
            .length = @intCast(length),
            .content = content,
        };
    }
};

const Action = enum(u8) {
    create,
    extract, //
    modify, // @todo: These three don't work yet.
    update, //

    fn fromString(string: []const u8) ParserError!Action {
        if (std.mem.eql(u8, string, "create")) {
            return .create;
        }
        if (std.mem.eql(u8, string, "extract")) {
            return .extract;
        }
        if (std.mem.eql(u8, string, "modify")) {
            return .modify;
        }
        if (std.mem.eql(u8, string, "update")) {
            return .update;
        }
        return ParserError.InvalidAction;
    }

    fn toString(action: Action) []const u8 {
        return switch (action) {
            .create => "CREATE",
            .extract => "EXTRACT",
            .modify => "MODIFY",
            .update => "UPDATE",
        };
    }
};

// Parser

pub fn fromFileAt(
    path: []u8,
    allocator: std.mem.Allocator,
) !Self {
    const relative_script_folder_path = std.fs.path.dirname(path);
    if (relative_script_folder_path == null) {
        return ParserError.InvalidPath;
    }
    const script_folder_path = try std.fs.cwd().realpathAlloc(
        allocator,
        relative_script_folder_path.?,
    );

    // Setup allocation

    // Read the script file's content

    const file = std.fs.cwd().openFile(path, .{
        .mode = std.fs.File.OpenMode.read_only,
    }) catch return ParserError.FileReadError;
    defer file.close();

    const source = file.readToEndAlloc(
        allocator,
        std.math.maxInt(u32),
    ) catch return ParserError.FileReadError;

    // Parse the script file's content into JSON

    const parsed_json = try std.json.parseFromSlice(
        std.json.Value,
        allocator,
        source,
        .{
            .duplicate_field_behavior = .use_first,
        },
    );
    const json = parsed_json.value;
    if (json != std.json.Value.object) {
        return ParserError.InvalidJsonString;
    }

    // > Extract and check known JSON values

    // >> Format Version

    const raw_format_version = json.object.get("format_version");
    if (raw_format_version == null) {
        return ParserError.InvalidVersion;
    }
    const format_version = raw_format_version.?.integer;
    parsed_json.deinit();

    if (format_version != 1) {
        return ParserError.InvalidVersion;
    }

    // >> Action

    const unchecked_action_string = json.object.get("action");

    if (unchecked_action_string == null) {
        std.log.err("error: field 'action' not found..\n", .{});
        return ParserError.InvalidAction;
    }
    if (unchecked_action_string.? != .string) {
        std.log.err("error: json-field 'action' must be a string.\n", .{});
        return ParserError.InvalidAction;
    }
    const action_string = unchecked_action_string.?.string;

    const action = try Action.fromString(action_string);

    // Partition Array

    const unchecked_partition_array = json.object.get("partitions");
    if (unchecked_partition_array == null) {
        return ParserError.InvalidPartitionArray;
    }
    if (unchecked_partition_array.? != .array) {
        return ParserError.InvalidPartitionArray;
    }
    const json_partitions = unchecked_partition_array.?.array.items;

    var partitions = std.ArrayList(Partition).init(allocator);

    var partition_index: u16 = 0;
    while (partition_index < json_partitions.len) {
        try partitions.append(try Partition.fromJson(
            script_folder_path,
            json_partitions[partition_index],
            partition_index,
            allocator,
        ));
        partition_index += 1;
    }

    return .{
        .action = action,
        .partitioning_scheme = PartitioningScheme.master_boot_record,
        .partitions = partitions.items,
    };
}
