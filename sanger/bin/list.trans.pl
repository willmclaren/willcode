#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($from, $to) = split /\t/, $_;
	
	$trans{$from} = $to;
}

close IN;

while(<>) {
	foreach $from(keys %trans) {
		$_ =~ s/\t$from\t/\t$trans{$from}\t/g;
	}
	
	print;
}