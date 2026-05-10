const std = @import("std");
const graphz = @import("graphz");
const debug = std.debug;
const assert = debug.assert;
const mem = std.mem;
const testing = std.testing;
const ArrayList = std.array_list.Managed;

const ts = @import("tree_sitter");
pub extern fn tree_sitter_wit() callconv(.c) *ts.Language;
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

test parse {
    const source =
        \\package test:my-package;
        \\
        \\interface inter {
        \\    type name = u8; 
        \\}
        \\
        \\worl my-world {
        \\    import foo: func() -> string;
        \\    export bar: func(s: string) -> u32;
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const tst_node = try parse(arena.allocator(), tree_sitter_wit, source);
    try testing.expectEqualStrings("source_file", tst_node.data.kind);
    debug.print("Done!\n", .{});
}
