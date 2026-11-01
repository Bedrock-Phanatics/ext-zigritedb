--TEST--
SIGIO no longer terminates the process once the extension is loaded, whatever order world handles close in
--SKIPIF--
<?php if(PHP_OS_FAMILY !== "Linux" || !function_exists("posix_kill")) die("skip needs posix on Linux"); ?>
--FILE--
<?php
$dirs = [];
for($i = 0; $i < 2; ++$i){
	$dirs[] = $dir = sys_get_temp_dir() . "/zigritedb-phpt-" . bin2hex(random_bytes(6));
	mkdir($dir);
}
$first = new Zigrite\World($dirs[0]);
$second = new Zigrite\World($dirs[1]);
$first->close();
// a closed handle puts back the handler it found, which must not be the default
posix_kill(getmypid(), 29);
echo "alive\n";
$second->close();
foreach($dirs as $dir){
	foreach(new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::CHILD_FIRST) as $file){
		$file->isDir() ? rmdir($file->getPathname()) : unlink($file->getPathname());
	}
	rmdir($dir);
}
?>
--EXPECT--
alive
