const std = @import("std");

const addGrammar = @import("./src/grammar.zig").addGrammar;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("tst", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const graphz = b.dependency("graphz", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addImport("graphz", graphz.module("graphz"));

    const tree_sitter = b.dependency("tree_sitter", .{
        .target = target,
        .optimize = optimize,
    });

    mod.addImport("tree_sitter", tree_sitter.module("tree_sitter"));

    // Bundle tree-sitter-wit grammar.
    addGrammar(b, mod, ".", "wit");

    const mod_tests = b.addTest(.{ .root_module = mod });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
