#!/usr/bin/perl

while(<>) {
	chomp;
	
	($a, $c) = split /\t/, $_;
	
	$total += $c;
	
	$counts{$a} = $c;
}

foreach $a(sort {$counts{$b} <=> $counts{$a}} keys %counts) {
	print "$a\t$counts{$a}\t".($counts{$a}/$total)."\n";
}