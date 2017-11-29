#!/usr/bin/perl

while(<>) {
	chomp;
	next unless /\d/;
	@data = split /\t/, $_;
	
	$total = $data[1]+$data[2]+$data[3]+$data[4];
	$cr = (($total-$data[4])/$total)*100;
	
	print "$data[0]\t$cr\n";
}