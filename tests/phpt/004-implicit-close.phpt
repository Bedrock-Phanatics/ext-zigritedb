--TEST--
A world freed without close() still closes the store, and another handle can open it afterwards
--FILE--
<?php
$dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir($dir);
for($round = 0; $round < 20; ++$round){
	$world = new Zigrite\World($dir);
	$world->writeChunk(0, $round, 0, ["," => "\x28", "/\x00" => "round $round"]);
	$world->getChunk(0, $round, 0);
	unset($world);
}
$world = new Zigrite\World($dir);
var_dump(count($world->listChunks(0)), $world->getChunk(0, 19, 0)["/\x00"]);
$world = null;
foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
	$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
}
rmdir($dir);
?>
--EXPECT--
int(20)
string(8) "round 19"
