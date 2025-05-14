const std = @import("std");
const arguments = @import("arguments.zig");
const selvafat = @import("selvafat.zig");
const DiskDescription = @import("script/DiskDescription.zig");

pub fn main() !void {
    const argument_set = try arguments.ArgumentSet.parseZ(
        std.os.argv[1..],
        std.heap.page_allocator,
    );

    _ = try DiskDescription.fromFileAt(
        argument_set.script_path.?,
        std.heap.smp_allocator,
    );
}
