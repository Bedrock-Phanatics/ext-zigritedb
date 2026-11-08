//! Declarations for ZigriteDB's C ABI 3 (`zigritedb.h`) as of ZigriteDB 1.3.0, which is linked in statically.
const std = @import("std");

pub const abi_version: u32 = 3;
pub const max_batch_records = 4096;
pub const max_batch_bytes = 64 * 1024 * 1024;
pub const max_value_size = 16 * 1024 * 1024;
pub const all_components: u32 = 0xffffffff;

pub const Status = enum(c_int) {
    ok,
    not_found,
    invalid_argument,
    buffer_too_small,
    out_of_memory,
    unsupported,
    corruption,
    io_error,
    needs_recovery,
    busy,
    batch_order,
    limit,
    cleanup_pending,
    permission_denied,
    no_space,
    read_only,
    needs_migration,
    mismatch,
    _,
};

pub const Component = struct {
    pub const version: u32 = 0x2c;
    pub const subchunk: u32 = 0x2f;
    pub const legacy_version: u32 = 0x76;
};

pub const Handle = opaque {};

pub const Options = extern struct {
    version: u32,
    struct_size: u32,
    max_open_regions: u32,
    max_keys: u32,
    max_segments: u32,
    batch_buffer_size: u32,
    max_segment_size: u64,
    buffered: u32,
    compression_threshold: u32,
    cache_bytes: u64,
    cache_shards: u32,
    skip_unchanged: u32,
    compact_min_bytes: u64,
    compact_live_percent: u32,
    reserved: u32,
};

pub const Key = extern struct {
    dimension: i32,
    chunk_x: i32,
    chunk_z: i32,
    subchunk_y: i32,
    component: u32,
};

pub const Region = extern struct {
    dimension: i32,
    x: i32,
    z: i32,
};

pub const Operation = extern struct {
    key: Key,
    remove: u32,
    value: ?[*]const u8,
    value_len: usize,
};

pub const ChunkRecord = extern struct {
    component: u32,
    subchunk_y: i32,
    offset: usize,
    length: usize,
};

pub const Stats = extern struct {
    get_calls: u64,
    writes: u64,
    records_written: u64,
    raw_bytes_written: u64,
    compressed_bytes_written: u64,
    disk_reads: u64,
    bytes_read: u64,
    fsync_count: u64,
    fsync_duration_ns: u64,
    segment_rotations: u64,
    compactions: u64,
    compaction_input_bytes: u64,
    compaction_output_bytes: u64,
    compaction_duration_ns: u64,
    recovery_attempts: u64,
    recovery_errors: u64,
    cache_hits: u64,
    cache_misses: u64,
    cache_evictions: u64,
    unchanged_write_skips: u64,
};

pub const Report = extern struct {
    chunk_records: u64,
    other_records: u64,
    bytes: u64,
    files: u64,
    regions: u64,
    problems: u64,
    message: [256]u8,
};

comptime {
    std.debug.assert(@sizeOf(Report) == 304);
    // the layouts the library asserts on its side
    std.debug.assert(@sizeOf(Options) == 72);
    std.debug.assert(@offsetOf(Options, "compression_threshold") == 36);
    std.debug.assert(@offsetOf(Options, "cache_bytes") == 40);
    std.debug.assert(@offsetOf(Options, "skip_unchanged") == 52);
    std.debug.assert(@offsetOf(Options, "compact_min_bytes") == 56);
    std.debug.assert(@offsetOf(Options, "compact_live_percent") == 64);
    std.debug.assert(@sizeOf(Key) == 20);
    std.debug.assert(@sizeOf(Operation) == 40);
    std.debug.assert(@sizeOf(ChunkRecord) == 24);
}

pub extern fn zg_status_message(status: c_int) [*:0]const u8;
pub extern fn zg_abi_version() u32;
pub extern fn zg_platform_supported() c_int;
pub extern fn zg_options_init(options: *Options) Status;
pub extern fn zg_open(path: [*]const u8, path_len: usize, options: *const Options, out: *?*Handle) Status;
pub extern fn zg_close(handle: *Handle) Status;
pub extern fn zg_write(handle: *Handle, batch_id: u64, operations: [*]const Operation, count: usize) Status;
pub extern fn zg_get_chunk(handle: *Handle, dimension: i32, chunk_x: i32, chunk_z: i32, buffer: ?[*]u8, capacity: usize, records: ?[*]ChunkRecord, record_capacity: usize, count: *usize, required: *usize) Status;
pub extern fn zg_aux_get(handle: *Handle, key: [*]const u8, key_len: usize, output: ?[*]u8, capacity: usize, required: *usize) Status;
pub extern fn zg_aux_put(handle: *Handle, key: [*]const u8, key_len: usize, value: [*]const u8, value_len: usize) Status;
pub extern fn zg_aux_delete(handle: *Handle, key: [*]const u8, key_len: usize) Status;
pub extern fn zg_flush(handle: *Handle) Status;
pub extern fn zg_list_regions(handle: *Handle, out: ?[*]Region, capacity: usize, count: *usize) Status;
pub extern fn zg_list_keys(handle: *Handle, dimension: i32, region_x: i32, region_z: i32, component: u32, out: ?[*]Key, capacity: usize, count: *usize) Status;
pub extern fn zg_stats_get(handle: *Handle, out: *Stats) Status;
pub extern fn zg_import(source: [*]const u8, source_len: usize, destination: [*]const u8, destination_len: usize, out: *Report) Status;
pub extern fn zg_export(source: [*]const u8, source_len: usize, destination: [*]const u8, destination_len: usize, out: *Report) Status;
pub extern fn zg_verify_bedrock(world: [*]const u8, world_len: usize, bedrock: [*]const u8, bedrock_len: usize, out: *Report) Status;
pub extern fn zg_verify(world: [*]const u8, world_len: usize, out: *Report) Status;
pub extern fn zg_migrate(source: [*]const u8, source_len: usize, destination: [*]const u8, destination_len: usize, out: *Report) Status;
