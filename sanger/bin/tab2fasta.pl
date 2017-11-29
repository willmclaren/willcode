#!/usr/bin/perl

while(<>) {
	chomp;
	($id, $seq) = split /\t/, $_;
	print ">$id\n$seq\n";
}
