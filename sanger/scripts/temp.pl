#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos, $num) = split /\t/, $_;
	
	$chr{$snp} = $chr;
	$num{$snp} = $num;
}

close IN;



while(<>) {
	chomp;
	
	@snps = split /\s+|\||\_/, $_;
	
	$window = scalar @snps;
	
	@markers = ();
	foreach $snp(@snps) {
		push @markers, $num{$snp};
	}
	
	$chr = $chr{$snps[0]};
	$markers = join " ", @markers;
	
	print (join '_', @snps);
	print "\t$chr\t$markers\n";
}