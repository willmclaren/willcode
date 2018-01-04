#!/usr/bin/perl

$write = 0;

while(<>) {
	if(/The output \(if any\) follows\:/) {
		$write = 1;
		$blank = <>;
	}
	
	else {
		print if $write;
	}
}