#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	next if /^Chr/;

	chomp;
	
	@data = split /\t/, $_;
	
	$ens{$data[0]}{$data[3]} = $_;
}

close IN;

while(<>) {
	chomp;
	
	($chr, $start, $end, $snps) = split /\t/, $_;
	
	foreach $gene(keys %{$ens{$chr}}) {
		@ens = split /\t/, $ens{$chr}{$gene};
		
		$e_s = $ens[1];
		$e_e = $ens[2];
		
		if($e_e < $e_s) {
			$temp = $e_s;
			$e_s = $e_e;
			$e_e = $temp;
		}
		
		if(
			(($start >= $e_s) && ($start <= $e_e))
			||
			(($end >= $e_s) && ($end <= $e_e))
		) {
			print $_."\t".$ens{$chr}{$gene}."\n";
		}
	}
}
	
	
	