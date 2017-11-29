#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos, $num) = split /\t/, $_;
	
	$chr{$snp} = $chr;
	$pos{$snp} = $pos;
}

close IN;



while(<>) {
	chomp;
	
	@snps = split /\s+|\||\_/, $_;
	
	print (join '_', @snps);
	
	print "\t$chr{$snps[0]}";
	print "\t$pos{$snps[0]}\t$pos{$snps[-1]}\n";
}