#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $sample, $gen, $score) = split /\s+/, $_;
	
	$blank{$sample}{$snp} = 1;
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos) = split /\s+/, $_;
	
	push @snps, $snp;
}

close IN;


while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	$sample = shift @data;
	
	if($blank{$sample}) {
		
		print $sample;
		
		for(1..5) {
			print "\t".(shift @data);
		}
		
		foreach $snp(@snps) {
			$a = shift @data;
			$b = shift @data;
		
			if($blank{$sample}{$snp}) {
				print "\t0 0";
			}
			
			else {
				print "\t$a $b";
			}
		}
		
		print "\n";
	}
	
	else {
		print "$_\n";
	}
}