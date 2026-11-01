--TEST--
Invalid keys, values, options and paths are rejected before reaching the store
--FILE--
<?php
$dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir($dir);
$world = new Zigrite\World($dir, ["buffered" => true, "cache_bytes" => 1 << 20, "skip_unchanged" => true]);

$cases = [
	"empty suffix" => fn() => $world->writeChunk(0, 0, 0, ["" => "x"]),
	"subchunk without y" => fn() => $world->writeChunk(0, 0, 0, ["/" => "x"]),
	"y on non-subchunk" => fn() => $world->writeChunk(0, 0, 0, [",\x00" => "x"]),
	"long suffix" => fn() => $world->writeChunk(0, 0, 0, ["QUARKDataVersion" => "x"]),
	"numeric two digits" => fn() => $world->writeChunk(0, 0, 0, [12 => "x"]),
	"int value" => fn() => $world->writeChunk(0, 0, 0, ["," => 40]),
	"coordinate range" => fn() => $world->getChunk(0, 1 << 40, 0),
	"empty aux key" => fn() => $world->auxPut("", "x"),
	"oversized value" => fn() => $world->writeChunk(0, 0, 0, ["1" => str_repeat("x", 16 * 1024 * 1024 + 1)]),
	"unknown option" => fn() => new Zigrite\World($dir, ["nope" => 1]),
	"option type" => fn() => new Zigrite\World($dir, ["buffered" => 1]),
	"option range" => fn() => new Zigrite\World($dir, ["cache_bytes" => -1]),
	"path with NUL" => fn() => new Zigrite\World("a\0b"),
	"missing directory" => fn() => new Zigrite\World($dir . "/missing"),
	"bad compaction percent" => fn() => new Zigrite\World($dir . "2", ["compact_live_percent" => 101]),
	"serialize" => fn() => serialize($world),
];
foreach($cases as $name => $case){
	try{
		$case();
		echo "$name: accepted\n";
	}catch(\Throwable $e){
		echo "$name: ", get_class($e), ($e instanceof Zigrite\Exception ? " code " . $e->getCode() : ""), "\n";
	}
}
var_dump($world->getChunk(0, 0, 0));

var_dump($world->auxGet("~local_player"));
$world->auxPut("~local_player", "player");
$world->auxPut("empty", "");
var_dump($world->auxGet("~local_player"), $world->auxGet("empty"));
$world->auxDelete("~local_player");
$world->auxDelete("never written");
var_dump($world->auxGet("~local_player"));
var_dump(Zigrite\World::isSupported());
$world->close();
unset($world);
foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
	$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
}
rmdir($dir);
?>
--EXPECT--
empty suffix: ValueError
subchunk without y: ValueError
y on non-subchunk: ValueError
long suffix: ValueError
numeric two digits: ValueError
int value: ValueError
coordinate range: ValueError
empty aux key: ValueError
oversized value: ValueError
unknown option: ValueError
option type: TypeError
option range: ValueError
path with NUL: ValueError
missing directory: Zigrite\Exception code 1
bad compaction percent: Zigrite\Exception code 2
serialize: Exception
NULL
NULL
string(6) "player"
string(0) ""
NULL
bool(true)
