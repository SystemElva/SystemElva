const std = @import("std");
const tokenizer = @import("tokenizer.zig");

pub fn parse_file(path: [*:0]u8, allocator: std.mem.Allocator) !void {
    var file = try std.fs.cwd().openFileZ(
        path,
        .{ .mode = std.fs.File.OpenMode.read_only },
    );
    const len_file = try file.getEndPos();
    const file_content = try file.readToEndAlloc(allocator, len_file);

    const token_list = try tokenizer.tokenize(file_content, allocator);
    try token_list.write_to(std.io.getStdOut());
}
