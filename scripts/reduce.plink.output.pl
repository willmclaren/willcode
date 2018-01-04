#!/usr/bin/perl

@cols = qw/6 8 10 12/;

$thresh = 0.05;

while(<>) {
	if(/^SNP\t/) {
		print;
		next;
	}
	
	$line = $_;
	
	@data = split /\t/, $_;
	
	$keep = 0;
	
	foreach $col(@cols) {
		$keep = 1 if $data[$col] <= $thresh && $data[$col] !~ /na/i;
	}
	
	print if $keep;
}