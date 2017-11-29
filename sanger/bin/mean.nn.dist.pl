#!/usr/bin/perl

$numsims = 1000;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chrom, $pos) = split /\t/, $_;
	
	$snps{$chrom}{$pos} = $snp;
	$chr{$snp} = $chrom;
	$pos{$snp} = $pos;
}

close IN;

while(<>) {
	next unless /HET/i;

	chomp;
	
	@data = split /\t/, $_;
	
	$hets{$data[0]}{$data[1]} = 1;
	
	$seen{$data[0]}{$chr{$data[1]}} = 1;
	
	push @{$ishet{$chr{$data[1]}}}, $pos{$data[1]};
}


foreach $sample(reverse sort {scalar keys %{$hets{$a}} <=> scalar keys %{$hets{$b}}} keys %hets) {
	print $sample;
		
	$bigtotal = 0;
	$bigcount = 0;
	$ptotal = 0;
	$pcount = 0;
	%counts = ();
	
	
	foreach $chrom(sort {$a <=> $b} keys %snps) {
		#print "\t$chrom\n";
	
		@pos = ();
		$total = 0;
		$count = 0;
		
		foreach $pos(sort {$a <=> $b} keys %{$snps{$chrom}}) {
			push @pos, $pos if $hets{$sample}{$snps{$chrom}{$pos}};
		}
		
		#print "$chrom\t".(scalar @pos)."\n";
		
		if(scalar @pos > 4) {
			for $i(0..$#pos) {
				$this = $pos[$i];
				
				if($i==0) {
					$dist = $pos[$i+1] - $pos[$i];
				}
				
				elsif($i==$#pos) {
					$dist = $pos[$i] - $pos[$i-1];
				}
				
				else {
					$dist = (sort {$a <=> $b} (($pos[$i+1]-$pos[$i]), ($pos[$i]-$pos[$i-1])))[0];
				}
				
				next if $dist >= 5000000;
				
				$total += $dist;
				$count++;
				
				$bigtotal += $dist;
				$bigcount++;
			}
			
			$mean = ($count ? ($total / $count) : 0);
			
			$counts{$chrom} = $count;
		}
	}
	
	
	# simulations
	$simresult = 0;
	
	$bigmean = ($bigcount ? ($bigtotal / $bigcount) : 0);
	
	for $sim(1..$numsims) {
		$sbigcount = 0;
		$sbigtotal = 0;
		$sbigmean = 0;
		
		foreach $chr(keys %counts) {
		
			next unless $counts{$chr};
			
# 			print "$chr\t$counts{$chr}\n";
			
			$num = $counts{$chr};
			
			$size = scalar @{$ishet{$chr}};
		
			%used = ();
		
			while($num--) {
				$ran = int(rand $size);
				
				while($used{$ishet{$chr}[$ran]}) {
					$ran = int(rand $size);
				}
				
				$used{$ishet{$chr}[$ran]} = 1;
			}
			
			@pos = sort {$a <=> $b} keys %used;
			
			if(scalar @pos > 4) {
				#print "$chr\t".(scalar @pos)."\tken\n";
			
				for $i(0..$#pos) {
					$this = $pos[$i];
					
					if($i==0) {
						$dist = $pos[$i+1] - $pos[$i];
					}
					
					elsif($i==$#pos) {
						$dist = $pos[$i] - $pos[$i-1];
					}
					
					else {
						$dist = (sort {$a <=> $b} (($pos[$i+1]-$pos[$i]), ($pos[$i]-$pos[$i-1])))[0];
					}
					
					next if $dist >= 5000000;
				
					$sbigtotal += $dist;
					$sbigcount++;
					
					#print "\td:$dist\n";
				}
			}
		}
		
		$sbigmean = ($sbigcount ? ($sbigtotal / $sbigcount) : 0);
		
		#print "$sbigmean\t$bigmean\n";
		
		$sbigmean = ($sbigcount ? ($sbigtotal / $sbigcount) : 0);
		$simresult++ if $sbigmean <= $bigmean;
	}
	
	$p = $simresult / $numsims;
	
	print "\t$bigcount\t$bigmean\t$p\n";
	
	#last;# if $arse++ > 10;
}