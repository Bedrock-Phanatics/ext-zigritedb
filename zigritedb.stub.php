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

        /**
         * Converts the Bedrock LevelDB world at $bedrockWorld into a new ZigriteDB world at $destination, which must
         * not exist. Every record and world file is compared with the source before the world appears there.
         * Blocks until done, so run it off the main thread.
         * @return array<string, int>
         */
        public static function importBedrock(string $bedrockWorld, string $destination): array {}

        /**
         * Writes the ZigriteDB world at $world out as a new Bedrock LevelDB world at $destination, checked like import.
         * @return array<string, int>
         */
        public static function exportBedrock(string $world, string $destination): array {}

        /**
         * Compares every record and world file of a ZigriteDB world with a Bedrock LevelDB world. Throws with code 17
         * when they differ.
         * @return array<string, int>
         */
        public static function verifyBedrock(string $world, string $bedrockWorld): array {}

        /**
         * Checks every frame of every region of a world nothing has open. Throws with code 6 when a region is damaged.
         * @return array<string, int>
         */
        public static function verify(string $world): array {}

        /**
         * Rewrites a world in an older ZigriteDB format as a new world at $destination.
         * @return array<string, int>
         */
        public static function migrate(string $source, string $destination): array {}

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
