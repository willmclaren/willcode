#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	#next unless $type =~ /het/i;
	
	$hets{$sample}{$snp} = $type;
}

close IN;




while(<>) {
	chomp;
	
	($snp, $sample, $geno, $ratio) = split /\t/, $_;
	
	if($hets{$sample}{$snp} =~ /het/i) {
		$hets_ratio{$sample} += $ratio;
		$hets_ratio_count{$sample}++;
		$ratio{$sample} += $ratio;
		$ratio_count{$sample}++;
	}
	
	elsif($hets{$sample}{$snp}) {
		$non_ratio{$sample} += $ratio;
		$non_ratio_count{$sample}++;
		$ratio{$sample} += $ratio;
		$ratio_count{$sample}++;
	}
}



foreach $sample(keys %ratio) {
	print
		"$sample\t".
		($ratio_count{$sample} ? ($ratio{$sample} / $ratio_count{$sample}) : 0)."\t$ratio_count{$sample}\t".
		($hets_ratio_count{$sample} ? ($hets_ratio{$sample} / $hets_ratio_count{$sample}) : 0)."\t$hets_ratio_count{$sample}\t".
		($non_ratio_count{$sample} ? ($non_ratio{$sample} / $non_ratio_count{$sample}) : 0)."\t$non_ratio_count{$sample}\n";
}