#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos) = split /\s+/, $_;
	
	push @{$gen{$chr}}, $pos;
	
	#$gen{$snp} = 1;
	#$pos{$snp} = $pos;
	#$chr{$snp} = $chr;
}

close IN;

foreach $chr(keys %gen) {
	@{$gen{$chr}} = sort {$a <=> $b} @{$gen{$chr}};
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
	
	$snp = $data[0];
	$chr = $chr{$snp};
	$pos = $pos{$snp};
	
	$prev = 9999999999999;
	
	foreach $p(@{$gen{$chr}}) {
		#print "$p\n";
	
		$d = $pos - $p;
		$d = 0 - $d if $d < 0;
		
		if($d > $prev) {
			$d = $prev;
			last;
		}
		
		$prev = $d;
	}
	
	print "$_\t$d\n";
}