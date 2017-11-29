#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chr, $pos) = split /\t/, $_;
	
	$chr{$snp} = $chr;
	$pos{$snp} = $pos;
}

close IN;


while(<>) {
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	$count{$sample}{$chr{$snp}}++;
}

foreach $sample(keys %count) {
	print $sample;
	
	foreach $chr(1..22) {
		print "\t".($count{$sample}{$chr} ? $count{$sample}{$chr} : 0);
	}
	
	print "\n";
}