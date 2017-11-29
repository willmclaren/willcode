#!/usr/bin/perl

while(<>) {
	chomp;
	
	($snp, $pos, $hap_a, $hap_b, $aff_a, $aff_b) = split /\t/, $_;
	
	($a, $b) = sort $hap_a, $hap_b;
	($hap_a, $hap_b) = ($a, $b);
	
	$match = 1;
	
	if($aff_a =~ /\?/) {
		if(($aff_b ne $hap_a) && ($aff_b ne $hap_b)) {
			$match = 0;
		}
	}
	
	elsif($hap_a =~ /\-/) {
		if(($aff_a ne $hap_b) && ($aff_b ne $hap_b)) {
			$match = 0;
		}
	}
	
	else {
		$match = 0 if $hap_a ne $aff_a;
		$match = 0 if $hap_b ne $aff_b;
	}
	
	print "$snp\t$pos\t$hap_a\t$hap_b\t$aff_a\t$aff_b\t$match\n";
}