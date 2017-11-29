#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$sample = $data[0];
	$z = $data[5];
	$neighbour = $data[6];
	
	$z{$sample}{$neighbour} = $z;
	$data{$sample}{$neighbour} = $_;
}

foreach $sample(keys %z) {
	$lowest = (sort {$z{$sample}{$a} <=> $z{$sample}{$b}} keys %{$z{$sample}})[0];
	
	print $data{$sample}{$lowest}."\n";
}