#!/usr/bin/perl

# SNP info
open IN, shift @ARGV;
while(<IN>) {
	chomp;
	($snp,$chr,$pos) = split /\t/, $_;
	$info{$snp}{'chr'} = $chr;
	$info{$snp}{'pos'} = $pos;
	
	$snps_by_chrom{$chr}{$pos} = $snp;
}
close IN;


# single SNP p-values
open IN, shift @ARGV;
while(<IN>) {
	chomp;
	($snp, $p) = split /\t/, $_;
	$single{$snp} = $p;
}
close IN;



# main data file
LINE: while(<>) {
	chomp;
	
	next unless /OMNIBUS/;
	
	@data = split /\t/, $_;
	
	$p = $data[6];
	
	#next unless $p <= 0.01;
	
	@snps = split /\|/, $data[-1];
	
	$chr = $info{$snps[0]}{'chr'};
	
	@p = ();
	
	foreach $snp(@snps) {
		next LINE if $single{$snp} < $p;
		push @p, $single{$snp};
	}
	
	print "$_\t$chr\t".(sort {$a <=> $b} @p)[0]."\n";
}