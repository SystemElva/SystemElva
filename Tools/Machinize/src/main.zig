const std = @import("std");
const parser = @import("parser/parser.zig");

pub fn main() !void {
    try parser.parse_file(std.os.argv[1], std.heap.page_allocator);
}
