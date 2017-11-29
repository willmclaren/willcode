#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $aa, $ab, $ba, $bb) = split /\s+/, $_;
	
	$conv{$snp}{$aa} = $ba;
	$conv{$snp}{$ab} = $bb;
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	push @snps, $data[1];
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	print shift @data;
	for(1..5) {
		print "\t".(shift @data);
	}
	
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
		
		if($conv{$snp}) {
			$a = ($conv{$snp}{$a} ? $conv{$snp}{$a} : 0);
			$b = ($conv{$snp}{$b} ? $conv{$snp}{$b} : 0);
		}
		
		print "\t".(join " ", sort ($a,$b));
	}
	
	print "\n";
}