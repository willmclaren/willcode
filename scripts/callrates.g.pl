#!/usr/bin/perl

%args_with_vals = ('o' => 1);

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}
	

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$sample = $data[1];
	$snp = $data[0];
	$geno = $data[2];
	
		
	if($geno =~ /n/i) {
		$snpmissing{$snp}++;
		$samplemissing{$sample}++;
	}
	
	$samples{$sample}++;
	$snps{$snp}++;
}

$numsnps = scalar keys %snps;
$numsamples = scalar keys %samples;

open OUT, ">".($args{'o'} ? $args{'o'}."_" : "")."sample.callrates";
foreach $sample(keys %samplemissing) {
	print OUT $sample."\t".((($numsnps - $samplemissing{$sample})/$numsnps)*100)."\n";
}
close OUT;

open OUT, ">".($args{'o'} ? $args{'o'}."_" : "")."snp.callrates";
foreach $snp(keys %snpmissing) {
	print OUT $snp."\t".((($numsamples - $snpmissing{$snp})/$numsamples)*100)."\n";
}
close OUT;
