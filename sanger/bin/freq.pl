#!/usr/bin/perl

while(<>) {
	chomp;

	($id, $count) = split /\s+/, $_;

	push @order, $id;
	$counts{$id} = $count;
	$total += $count;
}

foreach $id(@order) {
	print "$id\t$counts{$id}\t".($counts{$id}/$total)."\n";
}
