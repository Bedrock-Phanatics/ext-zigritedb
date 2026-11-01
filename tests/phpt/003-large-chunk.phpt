--TEST--
Chunks over the batch buffer are written in several batches and read back whole
--FILE--
<?php
$dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
mkdir($dir);
$world = new Zigrite\World($dir, ["batch_buffer_size" => 16 * 1024 * 1024]);

$records = ["," => "\x28"];
for($y = -4; $y < 20; ++$y){
	$records["/" . chr($y & 0xff)] = random_bytes(1024 * 1024);
}
$records["2"] = random_bytes(15 * 1024 * 1024);
$world->writeChunk(0, 5, 5, $records);
$world->close();

$world = new Zigrite\World($dir);
$read = $world->getChunk(0, 5, 5);
var_dump(count($read), $read === $records || (ksort($read, SORT_STRING) && ksort($records, SORT_STRING) && $read === $records));
// a small chunk after the big one reuses the grown buffer
$world->writeChunk(0, 6, 5, ["," => "\x28"]);
var_dump($world->getChunk(0, 6, 5));
$world->close();
foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
	$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
}
rmdir($dir);
?>
--EXPECT--
int(26)
bool(true)
array(1) {
  [","]=>
  string(1) "("
}
