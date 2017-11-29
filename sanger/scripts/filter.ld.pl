#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	$group{$_} = 'a';
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	$group{$_} = 'b';
}

close IN;


while(<>) {
	@data = split /\s+/, $_;
	
	next unless $group{$data[1]};
	next if $group{$data[1]} eq $group{$data[3]};
	
	print;
}