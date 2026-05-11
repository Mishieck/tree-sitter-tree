const std = @import("std");
const mem = std.mem;

pub const tree_sitter = @import("tree_sitter");
pub const grammar = @import("./grammar.zig");

pub const LanguageFactory = fn () callconv(.c) *tree_sitter.Language;
pub const node = @import("./node.zig");

pub fn parse(
    arena: mem.Allocator,
    getLanguage: *const LanguageFactory,
    source: []const u8,
) !node.Node {
    const lang = getLanguage();
    defer lang.destroy();

    const parser = tree_sitter.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);

    const tree = parser.parseString(source, null);
    defer tree.?.destroy();
    const ts_node = tree.?.rootNode();

    return try node.init(arena, source, &ts_node, null);
}
