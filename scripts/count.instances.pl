#!/usr/bin/perl

if($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	
	if($arg =~ f) {
		$freq = 1;
	}
}

while(<>) {
	chomp;
	
	$counts{$_}++;
	$total++;
}

foreach $item(sort {$counts{$b} <=> $counts{$a}} keys %counts) {
	print "$item\t$counts{$item}".($freq ? "\t".($counts{$item}/$total) : "")."\n";
}