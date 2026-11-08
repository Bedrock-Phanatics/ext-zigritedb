--TEST--
Worlds convert to Bedrock LevelDB and back, are checked against each other, and failures carry the reason
--SKIPIF--
<?php if(!Zigrite\World::isSupported()) die("skip ZigriteDB storage is Linux only"); ?>
--FILE--
<?php
$root = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir("$root/source/bedrock", 0777, true);
file_put_contents("$root/source/bedrock/level.dat", "level");
$world = new Zigrite\World("$root/source");
$world->writeChunk(0, -3, 7, ["," => "\x28", "/\xfc" => str_repeat("s", 5000), "2" => "entities"]);
$world->writeChunk(1, 4, -9, ["," => "\x28"]);
$world->auxPut("~local_player", "player");
$world->close();

function attempt(string $name, Closure $call) : void{
	try{
		$result = $call();
		echo "$name: ", json_encode($result), "\n";
	}catch(Zigrite\Exception $e){
		echo "$name: code ", $e->getCode(), ", ", $e->getMessage(), "\n";
	}
}

attempt("export", fn() => Zigrite\World::exportBedrock("$root/source", "$root/leveldb"));
var_dump(file_get_contents("$root/leveldb/level.dat"), is_dir("$root/leveldb/db"));
attempt("import", fn() => Zigrite\World::importBedrock("$root/leveldb", "$root/back"));
attempt("verify back", fn() => Zigrite\World::verifyBedrock("$root/back", "$root/leveldb"));
attempt("verify frames", fn() => Zigrite\World::verify("$root/back"));
attempt("destination exists", fn() => Zigrite\World::importBedrock("$root/leveldb", "$root/back"));
attempt("missing source", fn() => Zigrite\World::importBedrock("$root/missing", "$root/other"));

$world = new Zigrite\World("$root/back");
attempt("open world", fn() => Zigrite\World::verifyBedrock("$root/back", "$root/leveldb"));
$world->auxPut("~local_player", "changed");
$world->close();
attempt("changed record", fn() => Zigrite\World::verifyBedrock("$root/back", "$root/leveldb"));

try{
	Zigrite\World::importBedrock("", "x");
}catch(ValueError $e){
	echo get_class($e), "\n";
}
var_dump(is_dir("$root/other"), glob("$root/*partial*"));
exec("rm -rf " . escapeshellarg($root));
?>
--EXPECTF--
export: {"chunk_records":4,"other_records":1,"bytes":5016,"files":1,"regions":0,"problems":0}
string(5) "level"
bool(true)
import: {"chunk_records":4,"other_records":1,"bytes":5016,"files":1,"regions":0,"problems":0}
verify back: {"chunk_records":4,"other_records":1,"bytes":5016,"files":1,"regions":0,"problems":0}
verify frames: {"chunk_records":0,"other_records":0,"bytes":0,"files":0,"regions":%d,"problems":0}
destination exists: code 2, cannot import world: PathAlreadyExists (Invalid argument)
missing source: code 1, cannot import world: FileNotFound (Not found)
open world: code 9, worlds do not match: the ZigriteDB world is open in another program (Store is busy)
changed record: code 17, worlds do not match: record 7e6c6f63616c5f706c61796572 differs between the worlds (The worlds hold different data)
ValueError
bool(false)
array(0) {
}
