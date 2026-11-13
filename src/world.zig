//! `Zigrite\World`: a ZigriteDB world handle keyed the way Bedrock LevelDB chunk keys are, so callers can read and
//! write chunk records with the same per-chunk suffixes (tag byte, plus the Y byte for subchunks).
const std = @import("std");
const phpz = @import("phpz");
const native = @import("native.zig");
const root = @import("root.zig");

const c = phpz.c;
const zend = phpz.zend;
const Zval = phpz.Zval;
const exception = phpz.exception;
const Array = zend.Array;

// The read buffer outlives requests, so it can't come from the Zend allocator.
const gpa = std.heap.c_allocator;

pub const Class = phpz.Class("Zigrite\\World", World, .{ .init = .default, .deinit = World.deinit });

/// How ZigriteDB sizes a batch against its batch buffer: a frame header plus a header and checksum per record.
const frame_header = 24;
const record_overhead = 16;
/// Most chunks fit, and anything bigger is retried with the size the library reports.
const initial_buffer = 256 * 1024;
const initial_records = 64;
/// A rare huge chunk shouldn't keep its buffer for as long as the world stays open.
const max_retained_buffer = 1024 * 1024;

fn fail(status: native.Status, comptime what: [:0]const u8) exception.Error {
    const code: c_int = @backingInt(status);
    return exception.throwExceptionEx(root.ExceptionClass.entry, code, what ++ ": %s", .{native.zg_status_message(code)});
}

const World = struct {
    handle: ?*native.Handle = null,
    batch_limit: usize = 0,
    buffer: []u8 = &.{},
    records: []native.ChunkRecord = &.{},

    fn deinit(self: *World) void {
        if (self.handle) |handle| {
            const status = native.zg_close(handle);
            if (status != .ok) c.php_error_docref(null, c.E_WARNING, "Zigrite\\World was not closed cleanly: %s", native.zg_status_message(@backingInt(status)));
        }
        self.handle = null;
        self.release();
    }

    fn release(self: *World) void {
        gpa.free(self.buffer);
        gpa.free(self.records);
        self.buffer = &.{};
        self.records = &.{};
    }

    fn get(self: *World) !*native.Handle {
        return self.handle orelse exception.throwException(root.ExceptionClass.entry, "Zigrite\\World is closed", 0);
    }

    pub fn __construct(path: []const u8, options: ?*Array) !World {
        try checkPath(path, 1);
        var config: native.Options = undefined;
        if (native.zg_options_init(&config) != .ok) return exception.throwException(root.ExceptionClass.entry, "libzigritedb_native does not speak ABI 3", 0);
        if (options) |table| try parseOptions(table, &config);

        var handle: ?*native.Handle = null;
        const status = native.zg_open(path.ptr, path.len, &config, &handle);
        if (status != .ok) return fail(status, "cannot open world");
        return .{ .handle = handle.?, .batch_limit = config.batch_buffer_size };
    }

    pub fn isSupported() bool {
        return native.zg_platform_supported() != 0;
    }

    pub fn importBedrock(bedrock_world: []const u8, destination: []const u8) !*Array {
        return convert(native.zg_import, bedrock_world, destination, "cannot import world");
    }

    pub fn exportBedrock(world: []const u8, destination: []const u8) !*Array {
        return convert(native.zg_export, world, destination, "cannot export world");
    }

    pub fn verifyBedrock(world: []const u8, bedrock_world: []const u8) !*Array {
        return convert(native.zg_verify_bedrock, world, bedrock_world, "worlds do not match");
    }

    pub fn migrate(source: []const u8, destination: []const u8) !*Array {
        return convert(native.zg_migrate, source, destination, "cannot migrate world");
    }

    pub fn verify(world: []const u8) !*Array {
        try checkPath(world, 1);
        var report: native.Report = undefined;
        const status = native.zg_verify(world.ptr, world.len, &report);
        if (status != .ok) return failReport(status, "world is damaged", &report);
        return reportArray(&report);
    }

    /// Returns every record of the chunk keyed by its LevelDB suffix, or null when the chunk has none.
    pub fn getChunk(self: *World, dimension: i64, chunk_x: i64, chunk_z: i64) !?*Array {
        const handle = try self.get();
        const dim = try int32(dimension, 1);
        const x = try int32(chunk_x, 2);
        const z = try int32(chunk_z, 3);
        if (self.buffer.len == 0) try self.grow(initial_buffer, initial_records);
        defer if (self.buffer.len > max_retained_buffer) self.release();

        var attempts: usize = 0;
        while (true) : (attempts += 1) {
            var count: usize = 0;
            var required: usize = 0;
            const status = native.zg_get_chunk(handle, dim, x, z, self.buffer.ptr, self.buffer.len, self.records.ptr, self.records.len, &count, &required);
            switch (status) {
                .ok => return try recordArray(self.buffer, self.records[0..count]),
                .not_found => return null,
                .buffer_too_small => {
                    // sizes only change if the chunk is rewritten between attempts
                    if (attempts >= 4) return fail(status, "cannot read chunk");
                    try self.grow(@max(required, self.buffer.len), @max(count, self.records.len));
                },
                else => return fail(status, "cannot read chunk"),
            }
        }
    }

    fn grow(self: *World, bytes: usize, records: usize) !void {
        if (bytes > self.buffer.len) {
            // Nothing in the old buffer is needed, so it goes first and the two never exist together.
            gpa.free(self.buffer);
            self.buffer = &.{};
            self.buffer = gpa.alloc(u8, bytes) catch return oom();
        }
        if (records > self.records.len) {
            const fresh = gpa.alloc(native.ChunkRecord, records) catch return exception.throwException(root.ExceptionClass.entry, "out of memory", @backingInt(native.Status.out_of_memory));
            gpa.free(self.records);
            self.records = fresh;
        }
    }

    /// Puts each string and deletes each null in `$records`, keyed by LevelDB suffix, as one atomic batch. A chunk too
    /// big for the batch buffer is written in several batches instead, with its version records last.
    pub fn writeChunk(self: *World, dimension: i64, chunk_x: i64, chunk_z: i64, records: *Array) !void {
        const handle = try self.get();
        const dim = try int32(dimension, 1);
        const x = try int32(chunk_x, 2);
        const z = try int32(chunk_z, 3);
        const total = records.len();
        if (total == 0) return;
        // every suffix names a different record, so a chunk can't have more than this many
        if (total > 2 * 256) return exception.argumentValueError(4, "has too many records", .{});

        var inline_operations: [64]native.Operation = undefined;
        const operations = if (total <= inline_operations.len) inline_operations[0..total] else gpa.alloc(native.Operation, total) catch return oom();
        defer if (total > inline_operations.len) gpa.free(operations);

        var bytes: usize = frame_header;
        var used: usize = 0;
        var key_buffer: [32]u8 = undefined;
        var iterator = records.iterator();
        while (iterator.next()) |entry| : (used += 1) {
            const suffix: []const u8 = switch (entry.key) {
                .string => |name| name,
                // PHP stores numeric suffixes such as "1" (block entities) as integer keys
                .int => |index| std.fmt.bufPrint(&key_buffer, "{d}", .{index}) catch return exception.argumentValueError(4, "has an invalid record key", .{}),
            };
            var key: native.Key = .{ .dimension = dim, .chunk_x = x, .chunk_z = z, .subchunk_y = 0, .component = 0 };
            if (!parseSuffix(suffix, &key)) return exception.argumentValueError(4, "keys must be a record tag, plus a Y byte for subchunks", .{});
            const value = derefValue(entry.value);
            if (Zval.raw.is(value, .null)) {
                operations[used] = .{ .key = key, .remove = 1, .value = null, .value_len = 0 };
            } else if (Zval.raw.is(value, .string)) {
                const data = Zval.raw.asUnchecked(value, .string);
                if (data.len > native.max_value_size or frame_header + record_overhead + data.len > self.batch_limit) {
                    return exception.argumentValueError(4, "has a record too big for the batch buffer", .{});
                }
                operations[used] = .{ .key = key, .remove = 0, .value = data.ptr, .value_len = data.len };
                bytes += data.len;
            } else return exception.argumentValueError(4, "values must be strings, or null to delete", .{});
            bytes += record_overhead;
        }

        if (bytes <= self.batch_limit) {
            const status = native.zg_write(handle, 0, operations.ptr, total);
            if (status != .ok) return fail(status, "cannot write chunk");
            return;
        }
        try self.writeSplit(handle, operations);
    }

    /// Writes batches that each fit the batch buffer. The version records go last, so a chunk cut short by a crash
    /// still reads as its previous version wherever its records weren't replaced yet.
    fn writeSplit(self: *World, handle: *native.Handle, operations: []native.Operation) !void {
        var last: usize = operations.len;
        var i: usize = 0;
        while (i < last) {
            const component = operations[i].key.component;
            if (component == native.Component.version or component == native.Component.legacy_version) {
                last -= 1;
                std.mem.swap(native.Operation, &operations[i], &operations[last]);
            } else i += 1;
        }

        var start: usize = 0;
        while (start < operations.len) {
            var end = start;
            var bytes: usize = frame_header;
            while (end < operations.len) : (end += 1) {
                const size = record_overhead + operations[end].value_len;
                if (end > start and bytes + size > self.batch_limit) break;
                bytes += size;
            }
            const status = native.zg_write(handle, 0, operations[start..].ptr, end - start);
            if (status != .ok) return fail(status, "cannot write chunk");
            start = end;
        }
    }

    pub fn auxGet(self: *World, key: []const u8) !?*zend.String {
        const handle = try self.get();
        if (key.len == 0) return exception.argumentValueError(1, "must not be empty", .{});
        var required: usize = 0;
        var status = native.zg_aux_get(handle, key.ptr, key.len, null, 0, &required);
        while (true) {
            switch (status) {
                .not_found => return null,
                .ok, .buffer_too_small => {},
                else => return fail(status, "cannot read key"),
            }
            const out = zend.String.alloc(required, false);
            const capacity = required;
            status = native.zg_aux_get(handle, key.ptr, key.len, out.mutableSlice().ptr, capacity, &required);
            if (status == .ok and required == capacity) return out;
            out.release();
            if (status == .ok) status = .buffer_too_small;
        }
    }

    pub fn auxPut(self: *World, key: []const u8, value: []const u8) !void {
        const handle = try self.get();
        if (key.len == 0) return exception.argumentValueError(1, "must not be empty", .{});
        const status = native.zg_aux_put(handle, key.ptr, key.len, value.ptr, value.len);
        if (status != .ok) return fail(status, "cannot write key");
    }

    pub fn auxDelete(self: *World, key: []const u8) !void {
        const handle = try self.get();
        if (key.len == 0) return exception.argumentValueError(1, "must not be empty", .{});
        const status = native.zg_aux_delete(handle, key.ptr, key.len);
        if (status != .ok and status != .not_found) return fail(status, "cannot delete key");
    }

    /// Returns `[x, z]` pairs of every chunk in the dimension with a version record.
    pub fn listChunks(self: *World, dimension: i64) !*Array {
        const handle = try self.get();
        const dim = try int32(dimension, 1);

        var regions: std.ArrayList(native.Region) = .empty;
        defer regions.deinit(gpa);
        while (true) {
            var count: usize = 0;
            const status = native.zg_list_regions(handle, regions.items.ptr, regions.capacity, &count);
            if (status == .ok) {
                regions.items.len = count;
                break;
            }
            if (status != .buffer_too_small) return fail(status, "cannot list regions");
            regions.ensureTotalCapacityPrecise(gpa, count) catch return oom();
        }

        var keys: std.ArrayList(native.Key) = .empty;
        defer keys.deinit(gpa);
        var seen: std.AutoHashMapUnmanaged(u64, void) = .empty;
        defer seen.deinit(gpa);
        var list = Array.ListBuilder.init(0);
        errdefer list.finish().release();
        for (regions.items) |region| {
            if (region.dimension != dim) continue;
            for ([_]u32{ native.Component.version, native.Component.legacy_version }) |component| {
                while (true) {
                    var count: usize = 0;
                    const status = native.zg_list_keys(handle, region.dimension, region.x, region.z, component, keys.items.ptr, keys.capacity, &count);
                    if (status == .ok) {
                        keys.items.len = count;
                        break;
                    }
                    if (status != .buffer_too_small) return fail(status, "cannot list chunks");
                    keys.ensureTotalCapacityPrecise(gpa, count) catch return oom();
                }
                for (keys.items) |key| {
                    const id = @as(u64, @as(u32, @bitCast(key.chunk_x))) << 32 | @as(u32, @bitCast(key.chunk_z));
                    const found = seen.getOrPut(gpa, id) catch return oom();
                    if (found.found_existing) continue;
                    var pair = Array.ListBuilder.init(2);
                    pair.appendAssumeCapacity(.int, key.chunk_x);
                    pair.appendAssumeCapacity(.int, key.chunk_z);
                    var value: c.zval = undefined;
                    Zval.raw.set(&value, .array, pair.finish());
                    list.appendValue(&value);
                }
            }
        }
        return list.finish();
    }

    /// Makes every completed write durable. Without this, writes are already safe from a crash of this process, but
    /// not from power loss.
    pub fn flush(self: *World) !void {
        const status = native.zg_flush(try self.get());
        if (status != .ok) return fail(status, "cannot flush world");
    }

    pub fn close(self: *World) !void {
        const handle = try self.get();
        self.handle = null;
        self.release();
        // the handle is consumed even when closing fails
        const status = native.zg_close(handle);
        if (status != .ok) return fail(status, "cannot close world");
    }

    pub fn getStatistics(self: *World) !*Array {
        var stats: native.Stats = undefined;
        const status = native.zg_stats_get(try self.get(), &stats);
        if (status != .ok) return fail(status, "cannot read statistics");
        const names = @typeInfo(native.Stats).@"struct".field_names;
        const array = Array.init(names.len);
        inline for (names) |name| {
            var value: c.zval = undefined;
            Zval.raw.set(&value, .int, @as(i64, @bitCast(@field(stats, name))));
            _ = array.update(name, &value);
        }
        return array;
    }
};

fn checkPath(path: []const u8, arg: u32) !void {
    if (path.len == 0 or path.len > 4096 or std.mem.indexOfScalar(u8, path, 0) != null) return exception.argumentValueError(arg, "must be a directory path of at most 4096 bytes", .{});
}

const Conversion = fn ([*]const u8, usize, [*]const u8, usize, *native.Report) callconv(.c) native.Status;

/// Conversions can take minutes and touch only the paths given, so they run without a handle.
fn convert(comptime function: Conversion, first: []const u8, second: []const u8, comptime what: [:0]const u8) !*Array {
    try checkPath(first, 1);
    try checkPath(second, 2);
    var report: native.Report = undefined;
    const status = function(first.ptr, first.len, second.ptr, second.len, &report);
    if (status != .ok) return failReport(status, what, &report);
    return reportArray(&report);
}

fn failReport(status: native.Status, comptime what: [:0]const u8, report: *const native.Report) exception.Error {
    const code: c_int = @backingInt(status);
    const message: [*:0]const u8 = @ptrCast(&report.message);
    if (message[0] == 0) return fail(status, what);
    return exception.throwExceptionEx(root.ExceptionClass.entry, code, what ++ ": %s (%s)", .{ message, native.zg_status_message(code) });
}

fn reportArray(report: *const native.Report) !*Array {
    const names = .{ "chunk_records", "other_records", "bytes", "files", "regions", "problems" };
    const array = Array.init(names.len);
    inline for (names) |name| {
        var value: c.zval = undefined;
        Zval.raw.set(&value, .int, std.math.cast(i64, @field(report, name)) orelse std.math.maxInt(i64));
        _ = array.update(name, &value);
    }
    return array;
}

fn oom() exception.Error {
    return exception.throwException(root.ExceptionClass.entry, "out of memory", @backingInt(native.Status.out_of_memory));
}

fn int32(value: i64, arg: u32) !i32 {
    return std.math.cast(i32, value) orelse exception.argumentValueError(arg, "must be a 32-bit integer", .{});
}

fn derefValue(value: *c.zval) *c.zval {
    return if (Zval.raw.is(value, .reference)) Zval.raw.asUnchecked(value, .reference).val() else value;
}

fn named(key: []const u8) struct { c_int, [*]const u8 } {
    return .{ @intCast(@min(key.len, 64)), key.ptr };
}

const bool_options = .{ "buffered", "skip_unchanged" };
const int_options = .{ "cache_bytes", "compression_threshold", "max_open_regions", "batch_buffer_size", "compact_min_bytes", "compact_live_percent" };

/// The library validates ranges when opening, so this only checks types and that values fit the fields.
fn parseOptions(table: *Array, config: *native.Options) !void {
    var entries = table.iterator();
    while (entries.next()) |entry| {
        const key = switch (entry.key) {
            .string => |name| name,
            .int => return exception.argumentValueError(2, "must use string keys", .{}),
        };
        const value = derefValue(entry.value);
        inline for (bool_options) |name| {
            if (std.mem.eql(u8, key, name)) {
                if (!Zval.raw.is(value, .bool)) return exception.argumentTypeError(2, "option \"" ++ name ++ "\" must be bool", .{});
                @field(config, name) = @intFromBool(Zval.raw.asUnchecked(value, .bool));
                break;
            }
        } else {
            inline for (int_options) |name| {
                if (std.mem.eql(u8, key, name)) {
                    if (!Zval.raw.is(value, .int)) return exception.argumentTypeError(2, "option \"" ++ name ++ "\" must be int", .{});
                    @field(config, name) = std.math.cast(@FieldType(native.Options, name), Zval.raw.asUnchecked(value, .int)) orelse
                        return exception.argumentValueError(2, "option \"" ++ name ++ "\" is out of range", .{});
                    break;
                }
            } else return exception.argumentValueError(2, "has unknown option \"%.*s\"", named(key));
        }
    }
}

/// A suffix is a chunk record tag, followed by the signed Y byte for subchunks only, like Bedrock's LevelDB keys.
fn parseSuffix(suffix: []const u8, key: *native.Key) bool {
    if (suffix.len == 0 or suffix.len > 2) return false;
    const tag = suffix[0];
    if ((tag == native.Component.subchunk) != (suffix.len == 2)) return false;
    key.component = tag;
    key.subchunk_y = if (suffix.len == 2) @as(i8, @bitCast(suffix[1])) else 0;
    return true;
}

fn recordArray(buffer: []const u8, records: []const native.ChunkRecord) !*Array {
    const array = Array.init(@intCast(records.len));
    errdefer array.release();
    for (records) |record| {
        if (record.component > 0xff or record.offset > buffer.len or record.length > buffer.len - record.offset) {
            return exception.throwException(root.ExceptionClass.entry, "library returned an invalid chunk record", @backingInt(native.Status.corruption));
        }
        var suffix: [2]u8 = .{ @intCast(record.component), 0 };
        var len: usize = 1;
        if (record.component == native.Component.subchunk) {
            const y = std.math.cast(i8, record.subchunk_y) orelse return exception.throwException(root.ExceptionClass.entry, "library returned an invalid subchunk Y", @backingInt(native.Status.corruption));
            suffix[1] = @bitCast(y);
            len = 2;
        }
        var value: c.zval = undefined;
        Zval.raw.set(&value, .string, buffer[record.offset..][0..record.length]);
        // symtable keys match how PHP normalizes numeric suffixes like "1" and "2"
        _ = array.symtableUpdate(suffix[0..len], &value);
    }
    return array;
}
