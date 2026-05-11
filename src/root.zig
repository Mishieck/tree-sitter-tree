const std = @import("std");
const mem = std.mem;

const ts = @import("tree_sitter");
pub const grammar = @import("./grammar.zig");

pub const LanguageFactory = fn () callconv(.c) *ts.Language;
pub const node = @import("./node.zig");

pub fn parse(
    arena: mem.Allocator,
    getLanguage: *const LanguageFactory,
    source: []const u8,
) !node.Node {
    const lang = getLanguage();
    defer lang.destroy();

    const parser = ts.Parser.create();
    defer parser.destroy();
    try parser.setLanguage(lang);

    const tree = parser.parseString(source, null);
    defer tree.?.destroy();
    const ts_node = tree.?.rootNode();

    return try node.init(arena, source, &ts_node, null);
}
