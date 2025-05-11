const std = @import("std");
const Constructor = @import("Constructor.zig");

pub const Bootsector = struct {
    const Self = @This();

    // Volume Start (0 .. 11)

    jump_instruction: [3]u8 = .{
        0xeb, // JMP |
        0x3c, //     | forward by 0x3c bytes
        0x90, // NOP
    },

    // OEM Name ("SelvaFAT")
    oem_name: [8]u8 = .{ 0x53, 0x65, 0x6c, 0x76, 0x61, 0x46, 0x41, 0x54 },

    // DOS 2.0 BPB (11 . 24)

    logical_sector_size: u16 = 512,
    cluster_size: u8 = 4,
    num_reserved_sectors: u16 = 1,
    num_fats: u8 = 2,
    root_folder_capacity: u16 = 256,
    total_logical_sector_count: u16 = 2880,
    media_descriptor: u8 = 0x00,
    fat_size: u16 = 3,

    // DOS 3.0 BPB (24 .. 30)

    chs_physical_sectors_per_track: u16 = 18,
    chs_head_count: u16 = 1,
    hidden_sector_count: u16 = 0,

    // DOS 3.2 BPB (30 .. 32)

    num_logical_sectors_including_hidden: u16 = 2880,

    // Rest (32 .. 512)

    boot_code: [478]u8 = .{0x90} ** 478,
    boot_signature: [2]u8 = .{ 0x55, 0xaa },

    pub fn serialize(self: Self) [512]u8 {
        var bytes: [512]u8 = .{0} ** 512;
        @memcpy(bytes[0..3], self.jump_instruction[0..3]);
        @memcpy(bytes[3 .. 3 + 8], self.oem_name[0..8]);

        bytes[11] = @intCast(self.logical_sector_size & 0xff);
        bytes[12] = @intCast(self.logical_sector_size >> 8);

        bytes[13] = self.cluster_size;

        bytes[14] = @intCast(self.num_reserved_sectors & 0xff);
        bytes[15] = @intCast(self.num_reserved_sectors >> 8);

        bytes[16] = self.num_fats;

        bytes[17] = @intCast(self.root_folder_capacity & 0xff);
        bytes[18] = @intCast(self.root_folder_capacity >> 8);

        bytes[62] = 0xfa; // CLI
        bytes[63] = 0xf4; // HLT
        bytes[510] = 0x55;
        bytes[511] = 0xaa;

        return bytes;
    }
};
