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

`writeChunk()` is one atomic batch. A chunk too big for `batch_buffer_size` is written in several batches, version
records last. Writes are buffered by default: they reach the OS before the call returns, so they survive the process
crashing, and `flush()` or `close()` makes them survive power loss too. A world freed without `close()` is closed by its
destructor.

Errors throw `Zigrite\Exception` with ZigriteDB's status as the code, and invalid arguments throw `ValueError` or
`TypeError`. `Zigrite\World::isSupported()` is false where ZigriteDB can't store worlds (anything but Linux for now).

## Building

ZigriteDB builds with its own Zig version, so the extension links its C ABI 3 library rather than its Zig source.

```sh
# in ZigriteDB, with its Zig version
zig build -Doptimize=ReleaseSafe --prefix /opt/zigritedb

# here, with Zig 0.17
zig build -Doptimize=ReleaseSafe -Dzigritedb-prefix=/opt/zigritedb -Dphp-include-dir=$(php-config --include-dir)
zig build phpt -Dzigritedb-prefix=/opt/zigritedb -Dphp-include-dir=... -Dphp=$(which php)
```

`zig-out/modules/zigritedb.so` looks for `libzigritedb_native.so.3` in its own directory first, so install the two side
by side. Regenerate `zigritedb_arginfo.h` with phpz's `tools/php/gen_stub.php zigritedb.stub.php` after editing the stub.
