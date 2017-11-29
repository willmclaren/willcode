#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($s, $c, $p) = split /\t/, $_;
	
	$snps{$c}{$p} = $s;
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($sam, $s, $t) = split /\t/, $_;
	
	$rare{$sam}{$s} = $t;
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	($c, $a, $b) = split /\_/, $data[0];
	$sam = $data[1];
	$hets = 0;
	$homs = 0;
	
	foreach $p(keys %{$snps{$c}}) {
		next unless (($p >= $a) && ($p <= $b));
		
		$s = $snps{$c}{$p};
		
		$hets++ if $rare{$sam}{$s} =~ /het/i;
		$homs++ if $rare{$sam}{$s} =~ /hom/i;
	}
	
	print "$_\t$hets\t$homs\n";
}