const std = @import("std");
const arguments = @import("arguments.zig");
const selvafat = @import("selvafat.zig");

pub fn main() !void {
    const argument_set = try arguments.ArgumentSet.parseZ(
        std.os.argv[1..],
        std.heap.page_allocator,
    );
    try argument_set.writeToFile(std.io.getStdOut());

    const fat12_constructor: selvafat.fat12.Constructor = .{
        .len_partition = 512,
    };
    const file = try std.fs.cwd().createFileZ("image.img", .{
        .read = true,
        .truncate = true,
    });
    defer file.close();
    try fat12_constructor.toFile(
        file,
        std.heap.page_allocator,
    );
}
