#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @snps, (split /\s+/, $_)[0];
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($id, $seq) = split /\t/, $_;
	
	@{$trans{$id}} = split //, $seq;
	
	push @order, $id;
}

close IN;



open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($id, $seq) = split /\t/, $_;
	
	@{$un{$id}} = split //, $seq;
	
	push @order, $id;
}

close IN;


print "A T1D";
for(1..(scalar keys %trans)) {
	print " 2";
}
for(1..(scalar keys %un)) {
	print " 1";
}
print "\n";


foreach $snp(@snps) {
	print "M $snp";
	
	foreach $id(@order) {
		$base = ($trans{$id} ? shift @{$trans{$id}} : shift @{$un{$id}});
		print " $base";
	}
	
	print "\n";
}