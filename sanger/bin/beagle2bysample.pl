#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	push @snps, $split[(scalar @split > 1 ? ((scalar @split) - 3) : 0)];
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	push @samples, ($split[1] eq '1' ? $split[0] : $split[1]);
}

close IN;


while(<>) {
	next unless /^M/;
	
	chomp;
	
	@data = split /\s+/, $_;
	
	shift @data;
	
	$snp = shift @data;
	
	$i = 0;
	
	while(@data) {
		$sample = $samples[$i];
		
		$a = shift @data;
		$b = shift @data;
		
		$data{"$i\_A"}{$snp} = $a;
		$data{"$i\_B"}{$snp} = $b;
		
		$i++;
	}
}

foreach $sample(sort keys %data) {
	($i, $c) = split /\_/, $sample;

	print "$samples[$i]\_$c\t";
	
	$first = 1;
	
	foreach $snp(@snps) {
		print " " unless $first;
		$first = 0 if $first;
		print ($data{$sample}{$snp} ? $data{$sample}{$snp} : "-");
	}
	
	print "\n";
}