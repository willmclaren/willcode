#!/usr/bin/perl

# read SNP info
open IN, shift @ARGV;

$snpnum = 0;

while(<IN>) {
	chomp;
	
	($snp, $chr, $pos) = split /\t/, $_;
	
	$snps{$snp}{'chr'} = $chr;
	$snps{$snp}{'pos'} = $pos;
	$snporder{$snpnum} = $snp;
	
	$snpnum++;
}

close IN;


# go thru data
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$sample = shift @data;
	
	next if $seen{$sample};
	
	$snpnum = 0;
	
	while(@data) {
		$geno = shift @data;
		$snp = $snporder{$snpnum};
		
		if($geno =~ /n/i) {
			$snpmissing{$snp}++;
			$samplemissing{$sample}++;
		}
	
		$snpnum++;
	}
	
	$numsnps = $snpnum;
	
	$numsamples++;
	$seen{$sample} = 1;
}

open OUT, ">sample.callrates";
foreach $sample(keys %samplemissing) {
	print OUT $sample."\t".((($numsnps - $samplemissing{$sample})/$numsnps)*100)."\n";
}
close OUT;

open OUT, ">snp.callrates";
foreach $snp(keys %snpmissing) {
	print OUT $snp."\t".((($numsamples - $snpmissing{$snp})/$numsamples)*100)."\n";
}
close OUT;
