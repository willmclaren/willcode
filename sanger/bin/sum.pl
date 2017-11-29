#!/usr/bin/perl

while(<>) {
	chomp;

	@data = split /\t/, $_;

	$id = shift @data;

	print $id;

	$total = 0;

	foreach $d(@data) {
		print "\t$d";
		$total += $d;
	}
	
	print "\t$total\n";
}
