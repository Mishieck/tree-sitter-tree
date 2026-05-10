const std = @import("std");

pub fn addGrammar(
    b: *std.Build,
    mod: *std.Build.Module,
    comptime grammer_directory: []const u8,
    comptime grammar: []const u8,
) void {
    const source_directory = createSourceDirctory(grammer_directory, grammar);
    mod.addCSourceFile(createCsourceFile(b, createSourceFilePath(source_directory, "parser")));
    mod.addCSourceFile(createCsourceFile(b, createSourceFilePath(source_directory, "scanner")));
}

pub inline fn createSourceDirctory(
    comptime grammer_directory: []const u8,
    comptime grammar: []const u8,
) []const u8 {
    return grammer_directory ++ "/tree-sitter-" ++ grammar ++ "/src";
}

pub inline fn createSourceFilePath(
    comptime source_directory: []const u8,
    comptime filename: []const u8,
) []const u8 {
    return source_directory ++ "/" ++ filename ++ ".c";
}

pub fn createCsourceFile(b: *std.Build, comptime file_path: []const u8) std.Build.Module.CSourceFile {
    return .{
        .file = b.path(file_path),
        .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
    };
}
