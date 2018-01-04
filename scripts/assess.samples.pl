#!/usr/bin/perl


while(<>) {
	chomp;
	
	($snp, $sample, $geno, $qual) = split /\t/, $_;
	
	$counts{$sample}{$geno}++;
	$total_qual{$sample} += $qual;
	$total{$sample}++;
}

foreach $sample(keys %counts) {
	print "$sample\t$counts{$sample}{'NN'}\t$total{$sample}\t".($counts{$sample}{'NN'}/$total{$sample});
	
	foreach $geno(sort keys %{$counts{$sample}}) {
		print "\t$geno\t$counts{$sample}{$geno}";
	}
	
	print "\t".($total_qual{$sample} / $total{$sample});
	print "\n";
}