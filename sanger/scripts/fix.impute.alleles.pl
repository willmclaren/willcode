#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $a, $b) = split /\s+/, $_;
	
	$alleles{$snp} = $a.$b;
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 4) {
		$c1 = 2;
		$c2 = 3;
		$snp = $data[0];
	}
	
	else {
		$c1 = 3;
		$c2 = 4;
		$snp = $data[1];
	}
	
	if(!(defined $alleles{$snp})) {
		print "$_\n";
	}
	
	else {
		
		if($data[$c1] eq '-' or $data[$c2] eq '-') {
			if($data[$c1] eq '-') {
				($a, $b) = split //, $alleles{$snp};
				
				if($data[$c2] eq $a) {
					$data[$c1] = $b unless $b eq '0';
				}
				
				elsif($data[$c2] eq $b) {
					$data[$c1] = $a unless $a eq '0';
				}
			}
			
			else {
				($a, $b) = split //, $alleles{$snp};
				
				if($data[$c1] eq $a) {
					$data[$c2] = $b unless $b eq '0';
				}
				
				elsif($data[$c1] eq $b) {
					$data[$c2] = $a unless $a eq '0';
				}
			}
		}
		
		print (join " ", @data);
		print "\n";
	}
}