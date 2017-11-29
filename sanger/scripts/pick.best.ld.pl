#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$target = $data[1];
	$z = $data[2];
	$tag = $data[0];
	
	$z{$target}{$tag} = $z;
	$data{$target}{$tag} = $_;
}

foreach $sample(keys %z) {
	$lowest = (sort {$z{$sample}{$a} <=> $z{$sample}{$b}} keys %{$z{$sample}})[-1];
	
	print $data{$sample}{$lowest}."\n";
}
