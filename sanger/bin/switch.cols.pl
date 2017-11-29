#!/usr/bin/perl

$col_a = shift;
$col_b = shift;

$col_a--;
$col_b--;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$temp = $data[$col_a];
	$data[$col_a] = $data[$col_b];
	$data[$col_b] = $temp;
	
	print (join "\t", @data);
	print "\n";
}
