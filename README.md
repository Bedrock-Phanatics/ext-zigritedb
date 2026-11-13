# ext-zigritedb

PHP binding for [ZigriteDB](https://github.com/TrixNEW/ZigriteDB), the embedded Bedrock world store Quark can use in
place of LevelDB. Chunk records are read and written with the same per-chunk keys Bedrock uses in LevelDB, so a server
can keep one chunk codec for both.

```php
$world = new Zigrite\World("/path/to/world", ["batch_buffer_size" => 16 << 20]);

// records are keyed by LevelDB suffix: the record tag, plus the signed Y byte for subchunks
$world->writeChunk(0, $chunkX, $chunkZ, [
    "\x2c" => "\x28",          // version
    "\x2f\xfc" => $subChunk,   // subchunk y=-4
    "\x32" => null,            // delete the entities record
]);
$records = $world->getChunk(0, $chunkX, $chunkZ); // null when the chunk has no records

$world->auxPut("~local_player", $data);            // keys that aren't chunk records
$world->flush();                                   // fsync, survives power loss
$world->close();
```

`writeChunk()` is one atomic batch while the chunk fits `batch_buffer_size` (1 MiB by default, 64 MiB at most; a
record is limited to 16 MiB either way). A bigger chunk is written in several batches, version records last. Each of
those is atomic but the chunk is not: a crash or a failed batch in between leaves a mix of new and old records, and the
exception from a failed batch is the only notice. Raise `batch_buffer_size` to keep whole chunks atomic; it only limits
writes and costs no memory.

Writes are buffered by default: they reach the OS before the call returns, so they survive the process crashing, and
`flush()` or `close()` makes them survive power loss too. Call `flush()` once after a save pass rather than per chunk.
A world freed without `close()` is closed by its destructor. `close()` releases the world even when it throws.

After a crash, a region whose last write was cut short reopens without it; nothing older is touched. A region that
lost data it had already synced throws code 8 instead and stays as it is for `zigrite recover`.

Worlds convert with ZigriteDB's native converter, which keeps every LevelDB record and world file as is and compares
the result with the source before it appears at the destination. Each call blocks until done, so run it off the main
thread, and returns record and file counts:

```php
Zigrite\World::importBedrock("/worlds/leveldb", "/worlds/new");   // Bedrock LevelDB world -> ZigriteDB
Zigrite\World::exportBedrock("/worlds/new", "/worlds/back");      // ZigriteDB -> Bedrock LevelDB world
Zigrite\World::verifyBedrock("/worlds/new", "/worlds/leveldb");  // same records and files, or code 17
Zigrite\World::verify("/worlds/new");                             // every checksum, or code 6
Zigrite\World::migrate("/worlds/old-format", "/worlds/current");  // older ZigriteDB disk format
```

Errors throw `Zigrite\Exception` with ZigriteDB's status as the code, and invalid arguments throw `ValueError` or
`TypeError`. `Zigrite\World::isSupported()` is false where ZigriteDB can't store worlds (anything but Linux for now).

## Building

ZigriteDB is a pinned dependency, linked into the extension through its C ABI 3, so Zig 0.17 builds everything.

```sh
zig build -Doptimize=ReleaseSafe -Dphp-include-dir=$(php-config --include-dir)
zig build phpt -Dphp-include-dir=... -Dphp=$(which php)
```

Regenerate `zigritedb_arginfo.h` with phpz's `tools/php/gen_stub.php zigritedb.stub.php` after editing the stub.

## License

Apache License 2.0, like ZigriteDB. See [LICENSE](LICENSE).
