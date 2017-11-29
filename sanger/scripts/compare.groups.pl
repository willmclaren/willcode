#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $group) = split /\s+/, $_;
	
	$a{$group}{$snp} = 1;
}

close IN;


while(<>) {
	chomp;
	
	($snp, $group) = split /\s+/, $_;
	
	$b{$group}{$snp} = 1;
}


foreach $a(keys %a) {
	
	foreach $b(keys %b) {
		$match = 0;
		
		foreach $snp(keys %{$a{$a}}) {
			$match++ if $b{$b}{$snp};
		}
		
		print "$a\t$b\t$match\t".(scalar keys %{$a{$a}})."\t".(scalar keys %{$b{$b}})."\n" if $match;
	}
}