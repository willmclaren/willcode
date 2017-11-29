#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($hla, $f, $snps, $alleles, $f, $r, $d) = split /\s+/, $_;
	
	@snps = split /\,/, $snps;
	@alleles = split /\,/, $alleles;
	
	foreach $snp(@snps) {
		$alleles{$hla}{$snp} = shift @alleles;
	}
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($fam, $ind, $mum, $dad, $gen, $aff) = split /\s+/, $_;
	
	push @ind, $ind;
	$aff{$ind} = $aff;
}

close IN;



while(<>) {
	chomp;
	
	next unless /^M/;
	
	@data = split /\s+/, $_;
	
	shift @data;
	$snp = shift @data;
	
	$i = 0;
	
	while(@data) {
		$id = $ind[$i];
		
		$p{$id}{$snp}{'a'} = shift @data;
		$p{$id}{$snp}{'b'} = shift @data;
		
		$i++;
	}
	
	$seen{$snp} = 1;
	
	$i++;
}


open OUT, ">debug";

foreach $hla(sort keys %alleles) {
	
	# check if we have seen all the SNPs
	$count = 0;
	$n = 0;
	
	foreach $snp(keys %{$alleles{$hla}}) {
		$count++ if $seen{$snp};
		$n++;
	}
	
	if($n == $count) {
		print "$hla";
		
		
		foreach $id(keys %p) {
		
			$a = 0;
			$b = 0;
		
			foreach $snp(keys %{$alleles{$hla}}) {
				$a++ if $p{$id}{$snp}{'a'} eq $alleles{$hla}{$snp};
				$b++ if $p{$id}{$snp}{'b'} eq $alleles{$hla}{$snp};
			}
			
			# homozygote
			if(($a == $n) && ($b == $n)) {
				print "\t$id\(HOM\)";
				
				$byid{$id}{$hla} += 2;
			}
			
			# heterozygote
			elsif(($a == $n) || ($b == $n)) {
				print "\t$id\(HET\)";
				
				$byid{$id}{$hla}++;
			}
			
			else {
				print OUT "$hla\t$id\t$n\t$a\t$b\n";
			} 
		}
		
		print "\n";
	}
	
	else {
		print "$hla\tFound $count of $n SNPs\n";
	}
}


close OUT;

foreach $id(keys %byid) {
	print "$id";
	
	foreach $hla(sort keys %{$byid{$id}}) {
		while($byid{$id}{$hla}--) {
			print "\t$hla";
		}
	}
	print "\n";
}