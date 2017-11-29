#!/usr/bin/perl

while(<>) {
	chomp;
	
	($block, $sample, $geno) = split /\t/, $_;
	
	($a, $b) = split /\,/, $geno;
	
	$counts{$block}{$a}++;
	$counts{$block}{$b}++;
}

foreach $block(keys %counts) {
	print $block;
	
	foreach $geno(sort {$counts{$block}{$a} <=> $counts{$block}{$b}} keys %{$counts{$block}}) {
		print "\t$geno\t$counts{$block}{$geno}";
	}
	
	print "\n";
}