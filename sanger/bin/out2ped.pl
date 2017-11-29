#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	print shift @data;
	
	print "\t1\t0\t0\t0\t0";
	
	while(@data) {
		$geno = shift @data;
		
		$geno =~ tr/ACGTN/12340/;
		
		print "\t".substr($geno,0,1)." ".substr($geno,1,1);
	}
	
	print "\n";
}