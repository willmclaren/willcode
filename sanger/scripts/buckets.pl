#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($sample, $cat) = split /\t/, $_;
	
	$cat{$sample} = $cat;
}

close IN;

$bucket_size = 0.05;

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $ratio, $plate) = split /\t/, $_;
	
	$ratio{'all'}{$snp} += $ratio;
	$ratio_count{'all'}{$snp}++;
	
	$upper = $bucket_size;
	while($upper <= 1) {
		$buckets{'all'}{$snp}{$upper}++ if (($ratio > ($upper-$bucket_size)) && ($ratio <= $upper));
		$upper += $bucket_size;
	}
	
	if($cat{$sample}) {
		$ratio{$cat{$sample}}{$snp} += $ratio;
		$ratio_count{$cat{$sample}}{$snp}++;
		
		$upper = $bucket_size;
		
		while($upper <= 1) {
			$buckets{$cat{$sample}}{$snp}{$upper}++ if (($ratio > ($upper-$bucket_size)) && ($ratio <= $upper));
			$upper += $bucket_size;
		}
	}
}

foreach $snp(keys %{$ratio{'all'}}) {
	foreach $cat(sort keys %ratio) {
		print "$snp\t$cat\t".($ratio{$cat}{$snp} / $ratio_count{$cat}{$snp});
		
		$upper = $bucket_size;
		
		while($upper <= 1) {
			print "\t$buckets{$cat}{$snp}{$upper}";
			$upper += $bucket_size;
		}
		
		print "\n";
	}
}