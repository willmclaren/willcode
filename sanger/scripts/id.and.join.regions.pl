#!/usr/bin/perl

# map file
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

close IN;



# sig regions
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $from, $to, $sample, $hets, $p, $homs, $phoms) = split /\s+/, $_;
	
	$regions{$sample}{$chr}{$from} = $to;
}

close IN;


# full dist
while(<>) {
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	next unless $regions{$sample};
	next unless $type eq "HET";
	
	$full{$sample}{$chr{$snp}}{$snp} = 1;
}


foreach $sample(keys %regions) {
	foreach $chr(sort {$a <=> $b} keys %{$regions{$sample}}) {
		$prev = -99999;
		$prev_from = 0;
		
		foreach $from(sort {$a <=> $b} keys %{$regions{$sample}{$chr}}) {
			$to = $regions{$sample}{$chr}{$from};
			
			if($from == $prev) {
				$regions{$sample}{$chr}{$prev_from} = $to;
				delete $regions{$sample}{$chr}{$from};
			}
			
			$prev = $to;
			$prev_from = $from;
		}
		
		foreach $from(sort {$a <=> $b} keys %{$regions{$sample}{$chr}}) {
			$min = 999999999999999999;
			$max = 0;
			$f = "NA";
			$t = "NA";
			$count = 0;
			
			$to = $regions{$sample}{$chr}{$from};
		
			foreach $snp(keys %{$full{$sample}{$chr}}) {
				$pos = $pos{$snp};
			
				next unless (($pos/1000000 >= $from) && ($pos/1000000 <= $to));
				
				if($pos < $min) {
					$min = $pos;
					$f = $snp;
				}
				
				if($pos > $max) {
					$max = $pos;
					$t = $snp;
				}
				
				$count++;
			}
			
			print "$sample\t$chr\t$from\t$to\t$f\t$min\t$t\t$max\t$count\t".($max-$min)."\n";
		}
	}
}