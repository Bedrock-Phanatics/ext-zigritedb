const std = @import("std");
const builtin = @import("builtin");
const phpz = @import("phpz");
const native = @import("native.zig");

/// PHP owns signal handling, so threads started from this module skip Zig's alternate signal stack.
pub const std_options: std.Options = .{ .signal_stack_size = null };

comptime {
    const extension = @import("extension_info");
    phpz.module(.{
        .name = extension.name,
        .version = extension.version,
        .classes = &.{ ExceptionClass, WorldClass },
        .module_startup_fn = startup,
        .info_fn = info,
    });
}

fn startup() !void {
    if (native.zg_abi_version() != native.abi_version) {
        return phpz.exception.throwError(null, "libzigritedb_native speaks ABI %u, but zigritedb was built for ABI 3", .{native.zg_abi_version()});
    }
    keepSigioHandled();
}

const DlInfo = extern struct {
    fname: ?[*:0]const u8,
    fbase: ?*anyopaque,
    sname: ?[*:0]const u8,
    saddr: ?*anyopaque,
};
extern "c" fn dladdr(address: *const anyopaque, info: *DlInfo) c_int;

fn ignoreSignal(_: std.posix.SIG) callconv(.c) void {}

/// Every world handle runs a Zig `std.Io.Threaded`, which interrupts its threads with SIGIO and puts back the handler
/// it found when it's done, and so does ext-bedwire. If a world opened before the network closes first, SIGIO goes
/// back to its default, terminating the process when the network then stops. A handler installed up front keeps every
/// restore harmless. This module stays loaded so the handler can't outlive its code.
fn keepSigioHandled() void {
    if (comptime builtin.os.tag != .linux) return;
    const posix = std.posix;
    var current: posix.Sigaction = undefined;
    posix.sigaction(.IO, null, &current);
    if (current.handler.handler != posix.SIG.DFL) return;

    var self: DlInfo = undefined;
    if (dladdr(@ptrCast(&ignoreSignal), &self) == 0) return;
    const path = self.fname orelse return;
    if (std.c.dlopen(path, .{ .NOW = true, .NOLOAD = true, .NODELETE = true }) == null) return;

    const action: posix.Sigaction = .{ .handler = .{ .handler = ignoreSignal }, .mask = posix.sigemptyset(), .flags = 0 };
    posix.sigaction(.IO, &action, null);
}

fn info(m: *phpz.ModuleEntry) void {
    phpz.info.table.start();
    phpz.info.table.header(.{ "zigritedb support", "enabled" });
    phpz.info.table.row(.{ "version", m.version });
    const storage: [*:0]const u8 = if (native.zg_platform_supported() != 0) "supported" else "unsupported on this platform";
    phpz.info.table.row(.{ "storage", storage });
    phpz.info.table.end();
}

pub const ExceptionClass = phpz.Class("Zigrite\\Exception", struct {}, .{ .register = struct {
    fn register(register_fn: anytype) *phpz.ClassEntry {
        return register_fn(.{phpz.ClassEntry.builtin("RuntimeException")});
    }
}.register });

const WorldClass = @import("world.zig").Class;
