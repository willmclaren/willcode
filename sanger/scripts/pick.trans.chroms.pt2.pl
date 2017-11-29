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


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($fam, $chrom, $crap, $crap) = split /\s+/, $_;
	
	$look{$fam}{$chrom} = 1;
}

close IN;


while(<>) {
	chomp;
	
	($id, $chrom, $seq) = split /\t|\_/, $_;
	
	$fam = substr($id, 0, 6);
	
	if($look{$fam}) {
		if($seq =~ /\s+/) {
			@{$chroms{$fam}{$id}{$chrom}} = split /\s+/, $seq;
		}
		
		else {
			@{$chroms{$fam}{$id}{$chrom}} = split //, $seq;
		}
	}
}


foreach $fam(keys %look) {

	foreach $matpat(keys %{$look{$fam}}) {
 		#print ">$fam $matpat\n";
	
		$par = $fam.($matpat =~ /PAT/ ? "01" : "02");
			
		%match = ();
		%kids = ();
		
		foreach $chrom(keys %{$chroms{$fam}{$par}}) {
			$seq = join " ", @{$chroms{$fam}{$par}{$chrom}}[0..30];
			
			foreach $kid(keys %{$chroms{$fam}}) {
				next if $kid =~ /01$|02$/;
				
				$kids{$kid} = 1;
				
				foreach $c(keys %{$chroms{$fam}{$kid}}) {
					$seqa = join " ", @{$chroms{$fam}{$kid}{$c}}[0..30];
				
					#print "$par $seq\n$kid $seqa\n";
					
					if($seq eq $seqa) {
						$match{$chrom}++;
						last;
					}
				}
			}
		}
		
		foreach $chrom(keys %match) {
# 			print "\t$par\_$chrom matched $match{$chrom} of ".(scalar keys %kids)." kids\n";
			
			if($match{$chrom} == (scalar keys %kids)) {
				print "$par\t$chrom\n";
			}
		}
	}
}
			
		