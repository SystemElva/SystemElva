const std = @import("std");

pub const ArgumentSet = struct {
    const Self = @This();

    script_path: ?[]u8 = null,
    output_path: ?[]u8 = null,

    const Accept = enum(u16) {
        all,
        output_path,
    };

    pub const ParserError = error{
        missing_value_at_end,
        no_output_path,
        no_script_path,
    };

    pub fn parse(arguments: [][]u8) ParserError!Self {
        var argument_set: Self = .{};

        var accept = Accept.all;
        var argument_index: usize = 0;
        while (argument_index < arguments.len) {
            const argument = arguments[argument_index];

            switch (accept) {
                Accept.all => {
                    if (std.mem.eql(u8, argument, "-o")) {
                        argument_index += 1;
                        accept = Accept.output_path;
                        continue;
                    }
                    if (std.mem.eql(u8, argument, "--output")) {
                        argument_index += 1;
                        accept = Accept.output_path;
                        continue;
                    }
                    if (std.mem.startsWith(u8, argument, "-o=")) {
                        if (argument.len > 3) {
                            argument_set.output_path = argument[3..];
                        }
                        argument_index += 1;
                        continue;
                    }
                    if (std.mem.startsWith(u8, argument, "--output=")) {
                        if (argument.len > 9) {
                            argument_set.output_path = argument[9..];
                        }
                        argument_index += 1;
                        continue;
                    }
                    argument_set.script_path = argument;
                },
                Accept.output_path => {
                    argument_set.output_path = argument;
                },
            }
            accept = Accept.all;
            argument_index += 1;
        }
        if (accept != Accept.all) {
            return ParserError.missing_value_at_end;
        }
        if (argument_set.output_path == null) {
            return ParserError.no_output_path;
        }
        if (argument_set.script_path == null) {
            return ParserError.no_script_path;
        }
        return argument_set;
    }

    pub fn parseZ(
        arguments: [][*:0]u8,
        allocator: std.mem.Allocator,
    ) !Self {
        var argument_duplicates = try allocator.alloc([]u8, arguments.len);
        defer allocator.free(argument_duplicates);

        for (arguments, 0..) |argument, index| {
            const len_argument = std.mem.len(argument);
            argument_duplicates[index] = try allocator.alloc(u8, len_argument);
            @memcpy(
                argument_duplicates[index],
                arguments[index],
            );
        }
        return try Self.parse(argument_duplicates);
    }

    pub fn writeToFile(self: Self, file: std.fs.File) !void {
        try std.fmt.format(
            file.writer(),
            "script_path: {s}\n",
            .{self.script_path.?},
        );
        try std.fmt.format(
            file.writer(),
            "output_path: {s}\n",
            .{self.output_path.?},
        );
    }
};
