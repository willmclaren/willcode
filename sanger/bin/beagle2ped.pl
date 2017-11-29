#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @samples, (split /\s+/, $_)[0];
}
close IN;


while(<>) {
	next unless /^M/;
	chomp;
	
	@data = split /\s+/, $_;
	
	shift @data;
	$snp = shift @data;
	
	push @snps, $snp;
	
	foreach $sample(@samples) {
		$a = shift @data;
		$b = shift @data;
		
		$data{$sample}{$snp} = join " ", sort ($a, $b);
	}
}


foreach $sample(@samples) {
	print "$sample\t1\t0\t0\t0\t0";
	
	foreach $snp(@snps) {
		print "\t".$data{$sample}{$snp};
	}
	
	print "\n";
}
