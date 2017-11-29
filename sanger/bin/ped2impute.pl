#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	else {
		($chr, $snp, $null, $pos) = @data;
	}
	
	#$snps{$chr}{$pos} = $snp;
	push @snps, $snp;
	
	$chr{$snp} = $chr;
	$pos{$snp} = $pos;
}

close IN;


while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	if($data[0] != 1) {
		$sample .= '_'.(shift @data);
	}
	
	else {
		shift @data;
	}
	
	for(1..4) {
		shift @data;
	}
	
	push @samples, $sample;
	$j = (scalar @samples) - 1;
	
	foreach $i(0..$#snps) {
		$a = shift @data;
		$b = shift @data;
		
		$seen{$i}{$a} = 1 unless $a =~ /0|n/i;
		$seen{$i}{$b} = 1 unless $b =~ /0|n/i;
		
		$data{$i}{$j} = $a." ".$b;
		
		#print "$i $j $a $b\n";
	}
}

for $i(0..$#snps) {
	$snp = $snps[$i];

	print "SNP$chr{$snp} $snp $pos{$snp} ";
	
	@alleles = sort keys %{$seen{$i}};
	
	print "@alleles".(scalar @alleles > 1 ? "" : " ?");
	
	for $j(0..$#samples) {
		($a, $b) = split " ", $data{$i}{$j};
		
 		#print "$a $b twatz\n";
		
		if("$a$b" =~ /0|n/i) {
			print " 0 0 0";
		}
		
		elsif($a ne $b) {
			print " 0 1 0";
		}
		
		else {
			if($a eq $alleles[0]) {
				print " 1 0 0";
			}
			
			else {
				print " 0 0 1";
			}
		}
	}
	
	print "\n";
}