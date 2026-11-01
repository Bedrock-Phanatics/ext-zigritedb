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

ZigriteDB is a pinned dependency, linked into the extension through its C ABI 3, so Zig 0.17 builds everything.

```sh
zig build -Doptimize=ReleaseSafe -Dphp-include-dir=$(php-config --include-dir)
zig build phpt -Dphp-include-dir=... -Dphp=$(which php)
```

Regenerate `zigritedb_arginfo.h` with phpz's `tools/php/gen_stub.php zigritedb.stub.php` after editing the stub.

## License

Apache License 2.0, like ZigriteDB. See [LICENSE](LICENSE).
