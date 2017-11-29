#!/usr/bin/perl

# map file
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos) = split /\t/, $_;
	
	$snps{$chr}{$pos} = $snp;
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

close IN;


# list of known SNPs
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	$known{(split /\s+/, $_)[0]} = 1;
}

close IN;


# new SNPs

while(<>) {
	chomp;
	
	$snp = (split /\s+/, $_)[0];
	
	$chr = $chr{$snp};
	
	if($known{$snp}) {
		print "$snp\t$chr\t$pos{$snp}\tKNOWN\n";
		next;
	}
	
	$dist = 9999999999;
	$nearest = 'NONE';
	
	foreach $known(keys %known) {
		next unless $chr{$known} eq $chr;
		
		$d = $pos{$known} - $pos{$snp};
		$d = 0 - $d if $d < 0;
		
		if($d < $dist) {
			$dist = $d;
			$nearest = $known;
		}
	}
	
	print "$snp\t$chr\t$pos{$snp}\t$nearest\t$dist\n";
}