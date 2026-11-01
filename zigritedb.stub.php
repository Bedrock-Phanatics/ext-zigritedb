<?php

/**
 * @generate-class-entries
 * @undocumentable
 */

namespace Zigrite {
    /** The code is the ZigriteDB status, such as 6 for corrupt data. */
    class Exception extends \RuntimeException {}

    /**
     * @strict-properties
     * @not-serializable
     */
    final class World
    {
        /**
         * Opens the ZigriteDB world in an existing directory, creating it when the directory is empty.
         * Options: buffered, cache_bytes, compression_threshold, skip_unchanged, max_open_regions, batch_buffer_size,
         * compact_min_bytes, compact_live_percent.
         */
        public function __construct(string $path, array $options = []) {}

        public static function isSupported(): bool {}

        /** Records keyed by Bedrock LevelDB chunk key suffix: the record tag, plus the Y byte for subchunks. */
        public function getChunk(int $dimension, int $chunkX, int $chunkZ): ?array {}

        /** Writes every string and deletes every null in $records atomically. */
        public function writeChunk(int $dimension, int $chunkX, int $chunkZ, array $records): void {}

        public function auxGet(string $key): ?string {}

        public function auxPut(string $key, string $value): void {}

        public function auxDelete(string $key): void {}

        /** @return list<array{int, int}> */
        public function listChunks(int $dimension): array {}

        public function flush(): void {}

        public function close(): void {}

        /** @return array<string, int> */
        public function getStatistics(): array {}
    }
}
