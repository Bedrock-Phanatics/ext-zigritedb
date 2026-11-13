--TEST--
A write a crash cut short is dropped on reopen, while a cut into cleanly closed data is reported
--FILE--
<?php
function cut(string $dir, bool $keepCheckpoint) : void{
	$region = $dir . "/00000000-00000000-00000000.region";
	if(!$keepCheckpoint){
		unlink($region . "/INDEX");
	}
	$segment = $region . "/0000000000000001-0000000000000001.segment";
	$file = fopen($segment, "r+b");
	ftruncate($file, filesize($segment) - 3);
	fclose($file);
}

function remove(string $dir) : void{
	foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
		$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
	}
	rmdir($dir);
}

$dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir($dir);
$world = new Zigrite\World($dir);
$world->writeChunk(0, 0, 0, ["," => "\x28", "1" => "flushed"]);
$world->flush();
$world->writeChunk(0, 0, 0, ["1" => "buffered"]);
$world->close();

// without the checkpoint of a clean close, this is what a crash during the second write leaves
cut($dir, false);
$world = new Zigrite\World($dir);
var_dump($world->getChunk(0, 0, 0));
var_dump($world->getStatistics()["recovery_attempts"]);
$world->writeChunk(0, 0, 0, ["1" => "again"]);
$world->close();

$world = new Zigrite\World($dir);
var_dump($world->getChunk(0, 0, 0)[1], $world->getStatistics()["recovery_attempts"]);
$world->close();

// the checkpoint proves the close had synced these bytes, so losing them is damage, not a torn write
cut($dir, true);
$world = new Zigrite\World($dir);
try{
	$world->getChunk(0, 0, 0);
}catch(Zigrite\Exception $e){
	var_dump($e->getCode());
}
$world->close();
remove($dir);
?>
--EXPECT--
array(2) {
  [","]=>
  string(1) "("
  [1]=>
  string(7) "flushed"
}
int(1)
string(5) "again"
int(0)
int(8)
