const tokenizer = @import("tokenizer.zig");
const std = @import("std");

pub const ConverterError = error{
    InvalidEntryPoint,
    InvalidLabelName,
    UnknownAssembleTimeExpression,
    UnknownInstructionMnemonic,
    UnknownSyntaxElement,
    InvalidToken,
};

const InternalErrors = error{
    InvalidLabelName,
};

const Label = struct {
    name: []u8,
    offset: u32,
};

const LabelLookup = struct {
    used_labels: u32,
    labels: []Label,

    allocator: std.mem.Allocator,

    pub fn create(initial_space: u32, allocator: std.mem.Allocator) !*LabelLookup {
        var labels_capacity = initial_space;
        if (labels_capacity == 0) {
            labels_capacity = 512;
        }
        var label_lookup = try allocator.create(LabelLookup);
        label_lookup.used_labels = 0;
        label_lookup.labels = try allocator.alloc(Label, labels_capacity);
        label_lookup.allocator = allocator;
        return label_lookup;
    }

    pub fn lookup_label(self: LabelLookup, name: []u8) !Label {
        var label_index: u32 = 0;
        while (label_index < self.labels.len) {
            const label = self.labels[label_index];
            if (std.mem.eql(u8, label.name, name)) {
                return label;
            }
            label_index += 1;
        }
        return InternalErrors.InvalidLabelName;
    }

    pub fn new_label(
        self: *LabelLookup,
        name: []u8,
    ) !*Label {
        if (self.used_labels >= self.labels.len) {
            self.labels = try self.allocator.realloc(
                self.labels,
                self.labels.len * 2,
            );
        }
        const label: Label = .{
            .name = try self.allocator.dupe(u8, name),
            .offset = 0,
        };
        self.labels[self.used_labels] = label;
        self.used_labels += 1;
        return &self.labels[self.used_labels - 1];
    }
};

pub const InstructionConverter = struct {
    token_index: u32,
    token_list: tokenizer.TokenList,

    len_machine_code: u32,
    machine_code: []u8,

    label_lookup: *LabelLookup,
    allocator: std.mem.Allocator,

    fn convert_cli_instruction(self: *InstructionConverter) u32 {
        self.machine_code[self.len_machine_code] = 0xfa;
        self.len_machine_code += 1;
        return 1;
    }

    fn convert_instruction(self: *InstructionConverter) !u32 {
        const mnemonic_token = self.token_list.tokens[self.token_index];
        if (std.mem.eql(u8, mnemonic_token.string[0..3], "cli")) {
            return self.convert_cli_instruction();
        }
        return ConverterError.UnknownInstructionMnemonic;
    }

    fn parse_label(self: *InstructionConverter) !u32 {
        // const start_line = self.token_list.tokens[self.token_index].location[0];

        var offset: u32 = 0;
        var token = self.token_list.tokens[self.token_index];

        var len_label: u32 = 0;
        var is_sub_label = false;
        if (token.type == tokenizer.TokenType.sign) {
            if (!std.mem.eql(u8, token.string, ".")) {
                return ConverterError.InvalidLabelName;
            }
            is_sub_label = true;
            offset += 1;

            len_label += 1;
        }

        while ((self.token_index + offset) < self.token_list.num_tokens) {
            token = self.token_list.tokens[self.token_index + offset];
            if (token.type != tokenizer.TokenType.identifier) {
                return ConverterError.InvalidLabelName;
            }
            len_label += token.length;

            offset += 1;
            token = self.token_list.tokens[self.token_index + offset];

            if (token.type == tokenizer.TokenType.sign) {
                if (std.mem.eql(u8, token.string, ":")) {
                    break;
                }
                if (!std.mem.eql(u8, token.string, ".")) {
                    return ConverterError.InvalidLabelName;
                }
            }
            len_label += 1;
            offset += 1;
        }

        const num_label_tokens: u32 = offset;
        const full_label_string = try self.allocator.alloc(u8, len_label);
        var label_string_offset: usize = 0;

        offset = 0;
        while (offset < num_label_tokens) {
            token = self.token_list.tokens[self.token_index + offset];
            @memcpy(
                full_label_string[label_string_offset .. label_string_offset + token.string.len],
                token.string,
            );
            label_string_offset += token.string.len;
            offset += 1;
        }

        var label = try self.label_lookup.new_label(full_label_string);
        label.offset = self.len_machine_code;

        return offset + 1; // '+ 1' for the colon after the label name
    }

    fn convert_assemble_time_expression(self: *InstructionConverter) !u32 {
        const expression_name_token = self.token_list.tokens[self.token_index + 1];

        if (std.mem.eql(u8, expression_name_token.string[0..6], "padTo")) {}
        if (std.mem.eql(u8, expression_name_token.string[0..6], "bytes")) {}
        return ConverterError.UnknownAssembleTimeExpression;
    }

    fn is_instruction(self: *InstructionConverter) bool {
        if (self.token_list.tokens[self.token_index].type != tokenizer.TokenType.identifier) {
            return false;
        }
        return true;
    }

    fn is_assemble_time_expression(self: *InstructionConverter) bool {
        var token = self.token_list.tokens[self.token_index];
        if (token.type == tokenizer.TokenType.sign) {
            return false;
        }
        if (!std.mem.eql(u8, token.string, "@")) {
            return false;
        }
        if ((self.token_index + 1) < self.token_list.num_tokens) {
            return false;
        }

        token = self.token_list.tokens[self.token_index + 1];
        if (token.type != tokenizer.TokenType.identifier) {
            return false;
        }
        return true;
    }

    fn is_label(self: *InstructionConverter) bool {
        var offset: u32 = 0;

        // Check whether this is only a sub-section label.
        if (self.token_list.tokens[self.token_index].type == tokenizer.TokenType.sign) {
            if (!std.mem.eql(u8, self.token_list.tokens[self.token_index].string, ".")) {
                return false;
            }
            offset += 1;
        }

        if (self.token_list.tokens[self.token_index + offset].type != tokenizer.TokenType.identifier) {
            return false;
        }
        offset += 1;

        // @todo: Check whether a newline comes before the colon (that would be an error).

        const label_start_line = self.token_list.tokens[self.token_index].location[0];

        while ((self.token_index + offset) < self.token_list.num_tokens) {
            if (self.token_list.tokens[self.token_index + offset].location[0] != label_start_line) {
                break;
            }
            if (self.token_list.tokens[self.token_index + offset].type == tokenizer.TokenType.sign) {
                if (std.mem.eql(
                    u8,
                    self.token_list.tokens[self.token_index + offset].string,
                    ":",
                )) {
                    return true;
                }
            }
            offset += 1;
        }
        return false;
    }

    fn convert_next(self: *InstructionConverter) !u32 {
        if (is_label(self)) {
            return try parse_label(self);
        }
        if (is_instruction(self)) {
            return try convert_instruction(self);
        }
        if (is_assemble_time_expression(self)) {
            return try convert_assemble_time_expression(self);
        }
        return ConverterError.UnknownSyntaxElement;
    }

    pub fn convert(token_list: tokenizer.TokenList, allocator: std.mem.Allocator) ![]u8 {
        var converter: InstructionConverter = .{
            .token_index = 0,
            .token_list = token_list,
            .len_machine_code = 0,
            .machine_code = try allocator.alloc(u8, 8192),
            .label_lookup = try LabelLookup.create(256, allocator),
            .allocator = allocator,
        };
        while (converter.token_index < token_list.num_tokens) {

            // Always keep 512 bytes free for the nexts instruction converter to use
            if ((converter.len_machine_code + 512) >= converter.machine_code.len) {
                converter.machine_code = try allocator.realloc(
                    converter.machine_code,
                    converter.machine_code.len * 2,
                );
            }
            converter.token_index += try convert_next(&converter);
        }
        return allocator.realloc(converter.machine_code, converter.len_machine_code);
    }
};
