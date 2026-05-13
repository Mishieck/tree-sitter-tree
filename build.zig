const std = @import("std");
const path = std.fs.path;

pub const path_sep = &[1]u8{path.sep};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("tst", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/test.zig"),
        .target = target,
    });

    const graphz = b.dependency("graphz", .{
        .target = target,
        .optimize = optimize,
    });

    const tree_sitter = b.dependency("tree_sitter", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addImport("graphz", graphz.module("graphz"));
    mod.addImport("tree_sitter", tree_sitter.module("tree_sitter"));
    test_mod.addImport("graphz", graphz.module("graphz"));
    test_mod.addImport("tree_sitter", tree_sitter.module("tree_sitter"));
    test_mod.addImport("tst", mod);

    // Bundle tree-sitter-wit grammar.
    //
    // > [!NOTE]
    // > Check if tree-sitter-wit repo exists before adding grammar. This avoids failure of the
    // > build process when the this build function is run in other projects.
    if (fileExists("./tree-sitter-wit")) addGrammar(b, test_mod, ".", "", "wit");

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_mod_tests = b.addTest(.{ .root_module = test_mod });
    const run_test_mod_tests = b.addRunArtifact(test_mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_test_mod_tests.step);
}

pub fn addGrammar(
    b: *std.Build,
    mod: *std.Build.Module,
    comptime grammar_directory: []const u8,
    comptime grammar_sub_directory: []const u8,
    comptime grammar: []const u8,
) void {
    const source_directory = createSourceDirctory(grammar_directory, grammar_sub_directory, grammar);
    if (!fileExists(source_directory)) {
        std.debug.print("Missing grammar directory for '" ++ grammar ++ "'!\n", .{});
        return;
    }
    mod.addCSourceFile(createCsourceFile(b, createSourceFilePath(source_directory, "parser")));
    mod.addCSourceFile(createCsourceFile(b, createSourceFilePath(source_directory, "scanner")));
}

pub inline fn createSourceDirctory(
    comptime grammar_directory: []const u8,
    comptime grammar_sub_directory: []const u8,
    comptime grammar: []const u8,
) []const u8 {
    const sub_dir = path_sep ++ grammar_sub_directory;
    return grammar_directory ++ path_sep ++ "tree-sitter-" ++ grammar ++ sub_dir ++ path_sep ++ "src";
}

pub inline fn createSourceFilePath(
    comptime source_directory: []const u8,
    comptime filename: []const u8,
) []const u8 {
    return source_directory ++ path_sep ++ filename ++ ".c";
}

pub fn createCsourceFile(b: *std.Build, comptime file_path: []const u8) std.Build.Module.CSourceFile {
    return .{
        .file = b.path(file_path),
        .flags = &.{ "-std=c11", "-fno-sanitize=undefined" },
    };
}

pub fn fileExists(comptime file_path: []const u8) bool {
    var exists = true;

    std.fs.cwd().access(file_path, .{}) catch |err| {
        if (err == error.FileNotFound) {
            exists = false;
        } else {
            std.debug.print("Error checking file: {}\n", .{err});
            @panic("An unknown error occurred while checking if '" ++ file_path ++ "' exists!");
        }
    };

    return exists;
}
