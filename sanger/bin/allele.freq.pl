#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$allele = $data[0];
	$allele = $allele.$allele if length($allele) < 2;
	
	next if $allele =~ /n|0|9|\-/i;
	next if length($allele) != 2;
	
	if(scalar @data == 1) {
		if(substr($allele,0,1) eq substr($allele,1,1)) {
			$counts{$allele}++;
		}
		
		else {
			$hets++;
		}
		
		$total++;
	}
	
	else {
		if(substr($allele,0,1) eq substr($allele,1,1)) {
			$counts{$allele} = $data[1];
		}
		
		else {
			$hets = $data[1];
		}
		
		$total += $data[1];
	}
}

print "Frequencies:";

foreach $allele(sort {$counts{$a} <=> $counts{$b}} keys %counts) {
	$f = ((2*$counts{$allele})+$hets)/(2*$total);
	
	print "\t$allele\t$f";
}

print "\n";