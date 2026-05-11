const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const mem = std.mem;
const testing = std.testing;
const ArrayList = std.array_list.Managed;

const graphz = @import("graphz");
const ts = @import("tree_sitter");
const tst = @import("tst");

pub extern fn tree_sitter_wit() callconv(.c) *ts.Language;

test "parse" {
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
    const tst_node = try tst.parse(arena.allocator(), tree_sitter_wit, source);
    try testing.expectEqualStrings("source_file", tst_node.data.kind);
    debug.print("Done!\n", .{});
}
