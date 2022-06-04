const std = @import("std");

const bld = std.build;
const Arch = std.Target.Cpu.Arch;
const Builder = bld.Builder;
const Mode = std.builtin.Mode;

var mode: Mode = undefined;

const ProgData = struct {
    name: []const u8,
    output: []const u8,
    root: []const u8,
};

fn wasmProgram(b: *Builder, prog: ProgData) *bld.LibExeObjStep {
    const vers = b.version(0, 0, 0);
    const program = b.addSharedLibrary(prog.name, prog.root, vers);

    program.addPackagePath("liu", "src/liu/lib.zig");
    program.setBuildMode(mode);

    program.setTarget(.{ .cpu_arch = .wasm32, .os_tag = .freestanding });

    // Output straight to static folder by default to make things easier
    program.setOutputDir(prog.output);

    if (mode != .Debug) {
        program.strip = true;
    }

    program.install();
    b.default_step.dependOn(&program.step);

    return program;
}

pub fn build(b: *Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    mode = b.standardReleaseOptions();

    _ = wasmProgram(b, .{
        .name = "kilordle",
        .root = "./src/routes/kilordle/kilordle.zig",
        .output = "./src/static/kilordle/",
    });

    _ = wasmProgram(b, .{
        .name = "painter",
        .root = "./src/routes/painter/painter.zig",
        .output = "./src/static/painter/",
    });

    _ = wasmProgram(b, .{
        .name = "erlang",
        .root = "./src/routes/erlang/erlang.zig",
        .output = "./src/static/erlang/",
    });
}
