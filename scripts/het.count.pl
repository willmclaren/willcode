#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$sample = shift @data;
	$total = $data[1];
	
	for(1..3) {
		shift @data;
	}
	
	pop @data;
	
	$het = 0;
	
	while(@data) {
		$geno = shift @data;
		$count = shift @data;
		
		if(substr($geno, 0, 1) ne substr($geno, 1, 1)) {
			$het += $count;
		}
	}
	
	print "$sample\t$het\t$total\t".($het/$total)."\n";
}