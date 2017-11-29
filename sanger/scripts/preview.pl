#!/usr/bin/perl

for(1..10) {
	@data = split /\s+/, $_;
	
	print (join "\t", $data[1..10]);
	print "\n";
}