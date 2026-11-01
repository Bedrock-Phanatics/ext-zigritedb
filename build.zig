const std = @import("std");

const Phpz = @import("phpz").Phpz;

const package = @import("build.zig.zon");
const extension_name = "zigritedb";

pub fn build(b: *std.Build) void {
    const version = @import("builtin").zig_version;
    if (comptime version.major != 0 or version.minor != 17) {
        @compileError("ext-zigritedb requires Zig 0.17");
    }

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const php_include_dir = b.option([]const u8, "php-include-dir", "PHP include directory (main/, Zend/, TSRM/, ext/)") orelse "/usr/include/php";
    const php_lib_dir = b.option([]const u8, "php-lib-dir", "Windows only: PHP SDK library directory containing php8*.lib");
    const windows_zts = b.option(bool, "windows-zts", "Windows only: link against the thread-safe PHP library") orelse false;
    const windows_debug = b.option(bool, "windows-debug", "Windows only: build against a debug PHP SDK") orelse false;
    const libc_file = b.option([]const u8, "libc-file", "Libc paths file for C translation and extension compilation");
    const php = b.option([]const u8, "php", "PHP binary used for PHPT tests") orelse "php";

    const phpz_dep = b.dependency("phpz", .{});
    const phpz = Phpz.init(phpz_dep, .{
        .translator = .{
            .c_source_file = b.path("zigritedb.h"),
            .target = target,
            .optimize = optimize,
        },
        .libc_file = if (libc_file) |file| .{ .cwd_relative = file } else null,
        .php_include_dir = .{ .cwd_relative = php_include_dir },
        .php_lib_dir = if (php_lib_dir) |dir| .{ .cwd_relative = dir } else null,
        .windows_zts = windows_zts,
        .windows_debug = windows_debug,
    });

    const extension = phpz.addExtension(b, .{
        .name = extension_name,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    const extension_info = b.addOptions();
    extension_info.addOption([:0]const u8, "name", extension_name);
    extension_info.addOption([:0]const u8, "version", package.version);
    extension.root_module.addOptions("extension_info", extension_info);

    // ZigriteDB is linked in through its C ABI, built as its own root so its std options stay its own
    const zigritedb_dep = b.dependency("zigritedb", .{ .target = target, .optimize = optimize });
    const zigritedb = b.addLibrary(.{
        .name = "zigritedb_native",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = zigritedb_dep.path("src/c_api.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
        }),
    });
    extension.root_module.linkLibrary(zigritedb);
    if (libc_file) |file| {
        extension.setLibCFile(.{ .cwd_relative = file });
        zigritedb.setLibCFile(.{ .cwd_relative = file });
    }

    const filename = if (target.result.os.tag == .windows) "php_" ++ extension_name ++ ".dll" else extension_name ++ ".so";
    const install = b.addInstallFileWithDir(extension.getEmittedBin(), .{ .custom = "modules" }, filename);
    b.getInstallStep().dependOn(&install.step);

    const phpt = b.addSystemCommand(&.{php});
    phpt.addFileArg(phpz_dep.path("tools/php/run-tests.php"));
    phpt.addArgs(&.{ "-q", "--show-diff", "-p", php, "-d" });
    phpt.addPrefixedFileArg("extension=", extension.getEmittedBin());
    phpt.addArg("tests/phpt");
    phpt.setCwd(b.path("."));
    phpt.has_side_effects = true;
    b.step("phpt", "Run PHPT tests against the built extension").dependOn(&phpt.step);
}
