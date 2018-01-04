#!/usr/bin/perl

$val = '0';

if($ARGV[0] =~ /^\d+$/) {
	$val = shift @ARGV;
}

while(<>) {
	$_ =~ s/\t\t/\t$val\t/g;
	$_ =~ s/\t\n/\t$val\n/g;
	print;
}