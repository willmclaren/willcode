#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	$snps_to_switch{$_} = 1;
}

close IN;

while(<>) {
	chomp;
	
	($s, $a, $b) = split /\t/, $_;
	($snp, $sample) = split /\_/, $s;
	
	$b =~ tr/ACGT/TGCA/ if $snps_to_switch{$snp};
	
	$a = join "", (sort (split //, $a));
	$b = join "", (sort (split //, $b));

	$total++;
		
	if(($a =~ /n/i) || ($b =~ /n/i)) {
		$missing++;
		$snpmissing{$snp}++;
		$sampmissing{$sample}++;
		next;
	}
	
	if($a eq $b) {
		$snps{$snp}++;
		$samples{$sample}++;
		$matched++;
	}
	
	$snptotals{$snp}++;
	$samptotals{$sample}++;
}



print "Matched: $matched\nMissing: $missing\nTotal: $total\n\n";


foreach $sample(keys %samptotals) {
	print "$sample\t$samptotals{$sample}\t$samples{$sample}\t".($samptotals{$sample}-$samples{$sample})."\t$sampmissing{$sample}\n";
}

foreach $snp(keys %snptotals) {
	print "$snp\t$snptotals{$snp}\t$snps{$snp}\t".($snptotals{$snp}-$snps{$snp})."\t$snpmissing{$snp}\n";
}