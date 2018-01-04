#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	if(scalar @split == 3) {
		($snp, $chr, $pos) = @split;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @split;
	}
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
	
	$snps{$chr}{$pos} = $snp;
	
	$max{$chr} = $pos if $pos > $max{$chr};
}

close IN;


while(<>) {
	chomp;
	
	($sample, $snp, $type) = split /\s+/, $_;
	
	$hets{$sample}{$snp} = 1 if $type eq "HET";
}


foreach $sample(keys %hets) {
		
	%counts = ();
	%hetsin = ();
	
	$low = 0;
	$mid = 0;
	$high = 0;
	
	foreach $chr(1..22) {
		$a = 1;
		$b = $a + 4999999;
		
		@pos = sort {$a <=> $b} keys %{$snps{$chr}};
		$i = 0;
		
		while($b < $max{$chr}) {
			while(1) {
				$pos = $pos[$i];
				$snp = $snps{$chr}{$pos};
				last if $pos > $b;
				
				$i++;
				$counts{$chr}{$a}++ if $hets{$sample}{$snp};
			}
			
			if($counts{$chr}{$a} <= 2) {
				$low++;
				$hetsin{'low'} += $counts{$chr}{$a};
			}
			
			elsif($counts{$chr}{$a} <= 6) {
				$mid++;
				$hetsin{'mid'} += $counts{$chr}{$a};
			}
			
			else {
				$high++;
				$hetsin{'high'} += $counts{$chr}{$a};
			}
			
			#print "$sample\t$chr\t$a\-$b\t$counts{$chr}{$a}\n";
			
			$a = $b + 1;
			$b = $a + 4999999;
		}
	}
	
	print "$sample\t$low\t$mid\t$high\t$hetsin{'low'}\t$hetsin{'mid'}\t$hetsin{'high'}\n";
}