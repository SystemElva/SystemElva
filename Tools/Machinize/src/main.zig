const std = @import("std");
const parser = @import("parser/parser.zig");

pub fn main() !void {
    parser.parse_source();
}
