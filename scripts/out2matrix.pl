#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chrom, $pos) = split /\t/, $_;
	
	push @order, $snp;
}

close IN;

print "\t".(join "\t", @order);
print "\n";


while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	print shift @data;
	
	foreach $snp(@order) {
		$geno = shift @data;
		
		if($geno =~ /n/i) {
			$out = "00";
		}
		
		elsif(substr($geno,0,1) ne substr($geno,1,1)) {
			$out = "02";
		}
		
		elsif(!$seen{$snp}) {
			$out = "01";
			$seen{$snp}{$geno} = "01";
		}
		
		elsif($seen{$snp}{$geno}) {
			$out = $seen{$snp}{$geno};
		}
		
		else {
			$out = "03";
		}
		
		print "\t$out";
	}
	
	print "\n";
}