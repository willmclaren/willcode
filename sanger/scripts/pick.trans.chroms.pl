#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	
	$mum = shift @data;
	$dad = shift @data;
	
	$sex = shift @data;
	$aff = shift @data;
	
# 	print "$mum\t$dad\t$aff\n";
	
	if($mum && $dad && ($aff == 2)) {
		$aff{$fam}{$id} = 1;
	}
	
	$fam{$id} = $fam;
}

close IN;

while(<>) {
	chomp;
	
	($id, $source, $chrom) = split /\s+/, $_;
	
	$chroms{$id}{$source."_".$chrom} = 1;
	
	$seen{$fam{$id}} = 1;
}

foreach $fam(keys %seen) {
	%counts = ();

	foreach $kid(keys %{$aff{$fam}}) {
		next unless $chroms{$kid};
		
		foreach $chrom(keys %{$chroms{$kid}}) {
			$counts{$chrom}++;
		}
	}
	
# 	print ">Family $fam has ".(scalar keys %{$aff{$fam}})." affected children\n";
	
	$num = (scalar keys %{$aff{$fam}});
	
	foreach $chrom(keys %counts) {
		print "$fam\t$chrom\t$counts{$chrom}\t$num\n" if $num == $counts{$chrom};
	}
}