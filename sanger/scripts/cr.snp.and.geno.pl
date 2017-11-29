#!/usr/bin/perl

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $ratio) = split /\t/, $_;
	
	$per_snp{$snp} += $ratio;
	$miss_snp{$snp}++ if $geno =~ /NN/i;
	$per_snp_count{$snp}++;
	
	$per_genotype{$snp}{$geno} += $ratio;
	$per_genotype_count{$snp}{$geno}++;
}

foreach $snp(keys %per_snp) {
	print
		"$snp\t".
		($miss_snp{$snp} / $per_snp_count{$snp})."\t".
		($per_snp{$snp} / $per_snp_count{$snp})."\t".
		$per_snp_count{$snp};
	
	foreach $geno(sort keys %{$per_genotype{$snp}}) {
		print
			"\t$geno\t".
			($per_genotype{$snp}{$geno} / $per_genotype_count{$snp}{$geno})."\t".
			$per_genotype_count{$snp}{$geno};
	}
	
	print "\n";
}