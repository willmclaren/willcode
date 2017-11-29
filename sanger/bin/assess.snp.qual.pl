#!/usr/bin/perl


while(<>) {
	chomp;
	
	($snp, $sample, $geno, $qual) = split /\t/, $_;
	
	$total_qual{$snp} += $qual;
	$total{$snp}++;
}

foreach $snp(keys %total) {
	print "$snp\t".($total_qual{$snp} / $total{$snp});
	print "\n";
}