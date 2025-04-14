const std = @import("std");

pub fn main() !void {
    if (std.os.argv.len != 2) {
        std.debug.print("Usage: {s} <source-file>\n", .{std.os.argv[0]});
        return;
    }
    const filename = std.os.argv[1];
    var file = std.fs.cwd().openFileZ(filename, .{ .mode = std.fs.File.OpenMode.read_only }) catch {
        std.debug.print("Failed opening source file: {s}\n", .{filename});
        return;
    };
    const allocator = std.heap.page_allocator;
    const len_file = try file.getEndPos();
    const source = try file.readToEndAlloc(allocator, len_file);
    file.close();
    std.debug.print("Source:\n{s}\n", .{source});
    allocator.free(source);
}
