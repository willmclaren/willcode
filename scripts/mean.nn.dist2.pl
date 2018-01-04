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
		
		print "\t$chrom\t".(scalar @pos);
		
		if(scalar @pos <= 1) {
			print "\t\-";
		}
		
		else {
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
				
				$total += $dist;
				$count++;
				
				$bigtotal += $dist;
				$bigcount++;
			}
			
			$mean = ($count ? ($total / $count) : 0);
			
			print "\t$mean";
		}
	}
	
	print "\t".($bigcount ? ($bigtotal / $bigcount) : 0)."\n";
	#last;# if $arse++ > 10;
}