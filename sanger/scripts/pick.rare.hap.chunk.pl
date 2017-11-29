#!/usr/bin/perl

# common alleles
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $geno) = split /\s+/, $_;
	$a = substr($geno, 0, 1);
	
	$common{$snp} = $a;
}

close IN;


# map file
open IN, shift @ARGV;

while(<IN>) {
	@data = split /\s+/, $_;
	
	if(scalar @data == 4) {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	else {
		($snp, $chr, $pos) = @data;
	}
	
	push @snps, $snp;
}

close IN;


# ped file
while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	push @samples, $sample;
	
	for(1..5) { shift @data; }
	
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
	
		$geno{$snp}{$sample} = $a.$b;
	}
}

foreach $snp(@snps) {
	print "M $snp";

	foreach $sample(@samples) {
		if($common{$snp}) {
			$geno = $geno{$snp}{$sample};
			
			($a, $b) = split //, $geno;
			
			if($a eq $common{$snp}) {
				print " $a $b";
			}
			
			else {
				print " $b $a";
			}
		}
		
		else {
			print " 0 0";
		}
	}
	
	print "\n";
}