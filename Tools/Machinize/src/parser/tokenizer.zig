const std = @import("std");
const utility = @import("../utility.zig");

pub const TokenType = enum(u8) {
    identifier,
    binary,
    decimal,
    hexadecimal,
    sign,

    pub fn to_string(self: TokenType) [*:0]const u8 {
        switch (self) {
            .identifier => return "Identifier",
            .binary => return "BinaryInteger",
            .decimal => return "DecimalInteger",
            .hexadecimal => return "HexadecimalInteger",
            .sign => return "Sign",
        }
        return "INVALID";
    }
};

pub const Token = struct {
    type: TokenType,
    length: u32, // @todo: remove this and all references
    string: []u8,
    location: @Vector(2, u32),
};

pub const TokenList = struct {
    num_tokens: u32,
    tokens: []Token,

    pub fn write_to(self: TokenList, destination: std.fs.File) !void {
        const writer = destination.writer();
        var index: u32 = 0;
        while (index < self.num_tokens) {
            const token = self.tokens[index];
            try std.fmt.format(writer, "#{d} @ [{d}:{d}] (T: {s}): \"{s}\":{d}\n", .{
                index,
                token.location[0],
                token.location[1],
                token.type.to_string(),
                token.string,
                token.length,
            });
            index += 1;
        }
    }
};

pub const TokenizationError = error{
    UnicodeDecoderFailure,
    NonAsciiUsage,
    EndlessComment,
    InvalidNumberFormat,
};

pub fn tokenize(source: []u8, allocator: std.mem.Allocator) !TokenList {
    // @todo: Implement proper Unicode.

    var tokens_capacity: u32 = 1024;
    var token_list: TokenList = .{
        .num_tokens = 0,
        .tokens = try allocator.alloc(Token, 1024),
    };

    var line: u32 = 1;
    var column: u32 = 1;

    var token_index: u32 = 0;
    var offset: u32 = 0;
    while (offset < source.len) {
        if (token_index >= tokens_capacity) {
            tokens_capacity *= 2;
            token_list.tokens = try allocator.realloc(token_list.tokens, tokens_capacity);
        }
        if (source[offset] == '\n') {
            line += 1;
            column = 1;

            offset += 1;
        }

        if (std.ascii.isAlphabetic(source[offset]) or (source[offset] == '_')) {
            const token_start = offset;
            const start_column = column;
            while (offset < source.len) {
                if (!std.ascii.isAlphabetic(source[offset]) and !std.ascii.isAlphanumeric(source[offset]) and (source[offset] != '_')) {
                    break;
                }
                column += 1;
                offset += 1;
            }
            const len_token = offset - token_start;
            token_list.tokens[token_index] = .{
                .type = TokenType.identifier,
                .length = len_token,
                .string = try allocator.dupe(u8, source[token_start .. token_start + len_token]),
                .location = .{ line, start_column },
            };
            token_index += 1;
            continue;
        }

        if (std.ascii.isDigit(source[offset])) {
            const token_start = offset;
            const start_column = column;
            if (source[offset] == '0' and ((offset + 1) < source.len)) {
                if (source[offset + 1] == 'x') {
                    offset += 2;
                    while (offset < source.len) {
                        if (!std.ascii.isHex(source[offset])) {
                            break;
                        }
                        column += 1;
                        offset += 1;
                    }
                    const len_token = offset - token_start;
                    token_list.tokens[token_index] = .{
                        .type = TokenType.hexadecimal,
                        .length = len_token,
                        .string = try allocator.dupe(u8, source[token_start .. token_start + len_token]),
                        .location = .{ line, start_column },
                    };
                    token_index += 1;
                    continue;
                }
                if (source[offset + 1] == 'b') {
                    column += 2;
                    offset += 2;
                    while (offset < source.len) {
                        if ((source[offset] != '0' and source[offset] != '1')) {
                            if (std.ascii.isAlphanumeric(source[offset])) {
                                return TokenizationError.InvalidNumberFormat;
                            }
                            break;
                        }
                        column += 1;
                        offset += 1;
                    }
                    const len_token = offset - token_start;
                    token_list.tokens[token_index] = .{
                        .type = TokenType.binary,
                        .length = len_token,
                        .string = try allocator.dupe(u8, source[token_start .. token_start + len_token]),
                        .location = .{ line, start_column },
                    };
                    token_index += 1;
                    continue;
                }
            }
            while (offset < source.len) {
                if (!std.ascii.isDigit(source[offset])) {
                    break;
                }
                column += 1;
                offset += 1;
            }
            const len_token = offset - token_start;
            token_list.tokens[token_index] = .{
                .type = TokenType.decimal,
                .length = len_token,
                .string = try allocator.dupe(u8, source[token_start .. token_start + len_token]),
                .location = .{ line, start_column },
            };
            token_index += 1;
            continue;
        }

        if (source[offset] == '#') {
            if ((offset + 1) < source.len) {

                // Skip a single-line comment
                if (source[offset + 1] == '#') {
                    while (offset < source.len) {
                        if (source[offset] == '\n') {
                            break;
                        }
                        column += 1;
                        offset += 1;
                    }
                    continue;
                }

                // Skip a multi-line comment
                if (source[offset + 1] == '[') {
                    // Count the number of opening square brackets

                    column += 1;
                    offset += 1;
                    var num_opening_brackets: u16 = 0;
                    while (offset < source.len) {
                        num_opening_brackets += 1;
                        if (source[offset] != '[') {
                            break;
                        }
                        column += 1;
                        offset += 1;
                    }

                    // Skip until the correct amount of closing
                    // square brackets is found

                    skipper_loop: while (offset < source.len) {
                        var num_closing_brackets: u16 = 0;

                        while (offset < source.len) {
                            num_closing_brackets += 1;
                            if (num_closing_brackets >= num_opening_brackets) {
                                break :skipper_loop;
                            }
                            if (source[offset] != ']') {
                                break;
                            }
                            column += 1;
                            offset += 1;
                        }
                        column += 1;
                        offset += 1;
                    }
                    if (offset >= source.len) {
                        return TokenizationError.EndlessComment;
                    }
                    continue;
                }
            }
        }
        if (utility.is_sign(source[offset])) {
            var token_string: [*:0]u8 = @ptrCast(try allocator.alloc(u8, 2));
            token_string[0] = source[offset];
            token_string[1] = 0;
            token_list.tokens[token_index] = .{
                .type = TokenType.sign,
                .length = 1,
                .string = try allocator.dupe(u8, source[offset .. offset + 1]),
                .location = .{ line, column },
            };
            token_index += 1;

            column += 1;
            offset += 1;
            continue;
        }
        column += 1;
        offset += 1;
    }
    token_list.num_tokens = token_index;
    return token_list;
}
