const std = @import("std");
const debug = std.debug;
const assert = debug.assert;
const mem = std.mem;
const testing = std.testing;
const ArrayList = std.array_list.Managed;

const graphz = @import("graphz");
const ts = @import("tree_sitter");

pub const Node = graphz.Node(NodeData);

pub const NodeData = struct {
    kind: []const u8,
    text: []const u8,
    is_named: bool,
};

pub fn init(arena: mem.Allocator, source: []const u8, ts_node: *const ts.Node, parent: ?*Node) !Node {
    var children = ArrayList(*Node).init(arena);

    const tst_node = try arena.create(Node);
    const data = NodeData{
        .kind = ts_node.kind(),
        .text = getTsNodeText(source, ts_node),
        .is_named = ts_node.isNamed(),
    };
    tst_node.* = try graphz.TreeNode(NodeData).init(arena, data, parent);

    var cursor = ts_node.tree.walk();
    defer cursor.destroy();
    errdefer cursor.destroy();
    const ts_children = try ts_node.children(&cursor, arena);
    for (ts_children) |*child| {
        const child_node = try arena.create(Node);
        child_node.* = try init(arena, source, child, tst_node);
        try children.append(child_node);
    }

    return tst_node.*;
}

pub fn getTsNodeText(source: []const u8, ts_node: *const ts.Node) []const u8 {
    const start_byte = ts_node.startByte();
    const end_byte = ts_node.endByte();
    return source[start_byte..end_byte];
}
