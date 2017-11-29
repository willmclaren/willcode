#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos) = split /\s+/, $_;
	
	push @{$order{$chr}}, $pos;
	$gen{$chr}{$pos} = $snp;
	
	
	#$gen{$snp} = 1;
	#$pos{$snp} = $pos;
	#$chr{$snp} = $chr;
}

close IN;

foreach $chr(keys %gen) {
	@{$order{$chr}} = sort {$a <=> $b} @{$order{$chr}};
}

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos) = split /\s+/, $_;
	
	#next if $gen{$snp};
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

close IN;



while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$snp = $data[1];
	$chr = $chr{$snp};
	$pos = $pos{$snp};
	
	$prev = 9999999999999;
	
	foreach $p(@{$order{$chr}}) {
		#print "$p\n";
		$closest = $gen{$chr}{$p};
		
		$d = $pos - $p;
		$d = 0 - $d if $d < 0;
		
		if($d > $prev) {
			$d = $prev;
			$closest = $prev_closest;
			last;
		}
		
		$prev = $d;
		$prev_closest = $closest;
	}
	
	print "$_\t$d\t$closest\n";
}