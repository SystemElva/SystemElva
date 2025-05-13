const std = @import("std");
const Bootsector = @import("Header.zig").Bootsector;

pub const Constructor = struct {
    const Self = @This();

    /// Number of bytes in a logical sector. For performance reasons, this
    /// should match the size of a physical sector of the target disk.
    logical_sector_size: u16 = 512,

    /// Size of the partition in logical sectors.
    len_partition: u32,

    /// Number of logical sectors that form a clusters
    cluster_size: u8 = 4,

    /// Number of logical sectors reserved for the
    /// header and the extended boot code.
    ///
    /// Must be above or equal to 1.
    num_reserved_sectors: u16 = 1,

    /// Maximum number of entries in the Root Directory Region; how many
    /// folder entries have space at most considering the allocated space.
    ///
    /// Must fill complete logical sectors. A value of zero is erroneous.
    /// A folder entry is 32 bytes tall, thus, for a common sector size of
    /// 512 bytes, this must be a multiple of 16:
    /// (32 bytes per entry * 16 entries per sector = 512).
    root_folder_capacity: u16 = 256,

    /// Number of File Allocation Tables (FATs)
    num_fats: u8 = 2,

    /// Size of a single File Allocation Table (FAT) in logical sectors.
    ///
    /// Must be above or equal to 1.
    fat_size: u16 = 3,

    /// Path to the file containing the content for the reserved sectors.
    reserved_sector_content_path: []u8 = "",

    fn constructFat(
        self: Self,
        file: std.fs.File,
    ) !void {
        var bytes: [512]u8 = .{0} ** (512);
        bytes[0] = 0xf8;
        bytes[1] = 0xff;
        bytes[2] = 0xff;
        _ = try file.write(&bytes);

        var fat_sector_index: u32 = 1;
        while (fat_sector_index < self.fat_size) {
            const zeroes: [512]u8 = .{0} ** 512;
            _ = try file.write(&zeroes);
            fat_sector_index += 1;
        }
    }

    pub fn toFile(
        self: Self,
        file: std.fs.File,
        allocator: std.mem.Allocator,
    ) !void {
        var remaining_sectors: u32 = self.len_partition;

        const bootsector: Bootsector = .{
            .logical_sector_size = self.logical_sector_size,
            .cluster_size = self.cluster_size,
            .num_reserved_sectors = self.num_reserved_sectors,
            .root_folder_capacity = self.root_folder_capacity,
            .num_fats = self.num_fats,
            .fat_size = self.fat_size,
        };

        _ = try file.write(&bootsector.serialize());
        if (self.num_reserved_sectors > 1) {
            const reserved_sectors_file = try std.fs.cwd().openFile(
                self.reserved_sector_content_path,
                .{},
            );
            defer reserved_sectors_file.close();

            const reserved_region_capacity = (self.num_reserved_sectors - 1) * self.logical_sector_size;
            var reserved_region: []u8 = try allocator.alloc(u8, reserved_region_capacity);
            const byte_count = try reserved_sectors_file.read(reserved_region);

            _ = try file.write(reserved_region[0..byte_count]);
        }
        remaining_sectors -= self.num_reserved_sectors;

        var fat_index: u8 = 0;
        while (fat_index < self.num_fats) {
            try self.constructFat(file);
            fat_index += 1;
        }

        remaining_sectors -= self.num_fats * self.fat_size;

        var sector_index: u32 = 0;
        while (sector_index < remaining_sectors) {
            const zeroes: [512]u8 = .{0} ** 512;
            _ = try file.write(&zeroes);
            sector_index += 1;
        }
    }
};

test "create-fat12" {
    const constructor: Constructor = .{ .len_partition = 1024 };

    const file = try std.fs.cwd().createFile("image.img", .{});
    defer file.close();
    try constructor.construct(
        file,
        std.heap.page_allocator,
    );
}
