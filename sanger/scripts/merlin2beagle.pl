#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @snps, (split /\s+/, $_)[0];
}

close IN;


while(<>) {
	next if /FAMILY/;
	
	chomp;
	
	s/^\s+//g;
	s/\?/\-/g;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	$source = shift @data;
	
	$snpnum = 0;
	
	while(@data) {
		$a = shift @data;
		$snp = $snps[$snpnum];
		$snpnum++;
		
		push @{$out{$snp}}, $a;
	}
}

foreach $snp(keys %out) {
	print "M $snp ".(join " ", @{$out{$snp}});
	print "\n";
}