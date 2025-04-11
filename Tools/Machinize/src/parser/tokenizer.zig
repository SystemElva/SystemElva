const std = @import("std");

const TokenType = enum(u8) {
    integer,
    identifier,
    sign,

    pub fn to_string(self: TokenType) [*:0]const u8 {
        switch (self) {
            .integer => return "Integer",
            .identifier => return "Identifier",
            .sign => return "Sign",
        }
        return "INVALID";
    }
};

const Token = struct {
    type: TokenType,
    length: u32,
    string: [*:0]u8,
};

pub const TokenList = struct {
    num_tokens: u32,
    tokens: []Token,

    pub fn write_to(self: TokenList, destination: std.fs.File) !void {
        const writer = destination.writer();
        var index: u32 = 0;
        while (index < self.num_tokens) {
            const token = self.tokens[index];
            try std.fmt.format(writer, "#{d} (T: {s}): \"{s}\":{d}\n", .{
                index,
                token.type.to_string(),
                token.string,
                token.length,
            });
            index += 1;
        }
    }
};

pub const TokenizationError = error{ UnicodeDecoderFailure, NonAsciiUsage };

pub fn tokenize(source: []u8, allocator: std.mem.Allocator) !TokenList {
    // @todo: Implement proper Unicode.

    var tokens_capacity: u32 = 1024;
    var token_list: TokenList = .{
        .num_tokens = 0,
        .tokens = try allocator.alloc(Token, 1024),
    };

    var token_index: u32 = 0;
    var offset: u32 = 0;
    while (offset < source.len) {
        if (token_index >= tokens_capacity) {
            tokens_capacity *= 2;
            token_list.tokens = try allocator.realloc(token_list.tokens, tokens_capacity);
        }

        if (std.ascii.isAlphabetic(source[offset]) or (source[offset] == '_')) {
            const token_start: u32 = offset;
            while (offset < source.len) {
                if (!std.ascii.isAlphabetic(source[offset]) and !std.ascii.isAlphanumeric(source[offset]) and (source[offset] != '_')) {
                    break;
                }
                offset += 1;
            }
            const len_token = offset - token_start;
            var token_string: [*:0]u8 = @ptrCast(try allocator.alloc(u8, len_token + 1));
            @memcpy(token_string, source[token_start .. token_start + len_token]);
            token_string[len_token] = 0;
            token_list.tokens[token_index] = .{
                .type = TokenType.identifier,
                .length = len_token,
                .string = token_string,
            };
            token_index += 1;
            continue;
        }

        if (std.ascii.isDigit(source[offset])) {
            const token_start: u32 = offset;
            while (offset < source.len) {
                if (!std.ascii.isDigit(source[offset])) {
                    break;
                }
                offset += 1;
            }
            const len_token = offset - token_start;
            var token_string: [*:0]u8 = @ptrCast(try allocator.alloc(u8, len_token + 1));
            @memcpy(token_string, source[token_start .. token_start + len_token]);
            token_string[len_token] = 0;
            token_list.tokens[token_index] = .{
                .type = TokenType.integer,
                .length = len_token,
                .string = token_string,
            };
            token_index += 1;
            continue;
        }
        offset += 1;
    }
    token_list.num_tokens = token_index;
    return token_list;
}
