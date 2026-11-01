--TEST--
Chunk records round trip by LevelDB suffix and survive reopening
--FILE--
<?php
$dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir($dir);

$world = new Zigrite\World($dir);
$records = [
	"," => "\x28",
	"/\xfc" => str_repeat("a", 1000),
	"/\x00" => "subchunk 0",
	"/\x13" => "subchunk 19",
	"1" => "block entities",
	"2" => "entities",
	"6" => "\x02",
	"+" => str_repeat("\x00", 512) . "biomes",
];
$world->writeChunk(0, -3, 7, $records);
$world->writeChunk(1, -3, 7, ["," => "\x28", "/\x05" => "nether"]);

$read = $world->getChunk(0, -3, 7);
ksort($read, SORT_STRING);
ksort($records, SORT_STRING);
var_dump($read === $records);
var_dump(isset($read["1"], $read[2]));
var_dump($world->getChunk(1, -3, 7) === ["," => "\x28", "/\x05" => "nether"]);
var_dump($world->getChunk(0, -3, 8));

$world->writeChunk(0, -3, 7, ["2" => null, "/\x00" => null, "/\x01" => "new"]);
$world->close();

$world = new Zigrite\World($dir);
$read = $world->getChunk(0, -3, 7);
var_dump(isset($read[2]), isset($read["/\x00"]), $read["/\x01"], $read["1"]);
$chunks = $world->listChunks(0);
var_dump($chunks);
var_dump(count($world->listChunks(1)), count($world->listChunks(2)));
$world->writeChunk(0, 100, -100, []);
var_dump($world->getChunk(0, 100, -100));
$world->flush();
$stats = $world->getStatistics();
var_dump(is_int($stats["writes"]), $stats["get_calls"] > 0);
$world->close();

try{
	$world->getChunk(0, 0, 0);
}catch(Zigrite\Exception $e){
	echo $e->getMessage(), "\n";
}
foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
	$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
}
rmdir($dir);
?>
--EXPECT--
bool(true)
bool(true)
bool(true)
NULL
bool(false)
bool(false)
string(3) "new"
string(14) "block entities"
array(1) {
  [0]=>
  array(2) {
    [0]=>
    int(-3)
    [1]=>
    int(7)
  }
}
int(1)
int(0)
NULL
bool(true)
bool(true)
Zigrite\World is closed
