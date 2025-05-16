const std = @import("std");
const arguments = @import("arguments.zig");

const DiskDescription = @import("script/DiskDescription.zig");

pub fn main() !u8 {
    _ = arguments.ArgumentSet.parseZ(
        std.os.argv[1..],
        std.heap.smp_allocator,
    ) catch |err| {
        std.log.err("failed parsing arguments ({s})", .{@errorName(err)});
        return 1;
    };

    return 0;
}
