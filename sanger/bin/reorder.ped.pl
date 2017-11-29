#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chr, $pos) = split /\s+/, $_;
	
	push @order, $snp;
	
	$snps{$chr}{$pos}{$snp} = 1;
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	print shift @data;
	
	for(1..5) {
		print "\t".(shift @data);
	}
	
	foreach $snp(@order) {
		$a = shift @data;
		$b = shift @data;
		
		$data{$snp} = "$a $b";
	}
	
	foreach $chr(sort {$a <=> $b} keys %snps) {
		foreach $pos(sort {$a <=> $b} keys %{$snps{$chr}}) {
			foreach $snp(keys %{$snps{$chr}{$pos}}) {
				print "\t".($data{$snp} ? $data{$snp} : "0 0");
			}
		}
	}
	
	print "\n";
}