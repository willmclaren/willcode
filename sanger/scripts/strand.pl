#!/usr/bin/perl

open IN, shift @ARGV;
while(<IN>) {
	chomp;
	@data = split /\t/, $_;
	$snp = shift @data;
	
	foreach $a(@data) {
		$a{$snp}{$a} = 1;
	}
	
	$s{$snp} = 1;
}
close IN;

open IN, shift @ARGV;
while(<IN>) {
	chomp;
	@data = split /\t/, $_;
	$snp = shift @data;
	
	foreach $a(@data) {
		$b{$snp}{$a} = 1;
	}
	
	$s{$snp} = 1;
}
close IN;


foreach $snp(keys %s) {
	$a = join "", sort keys %{$a{$snp}};
	$b = join "", sort keys %{$b{$snp}};
	
	if(($a eq "CG") || ($b eq "CG") || ($a eq "AT") || ($b eq "AT")) {
		print "$snp\tDUNNO\n";
	}
	
	next if $a eq $b;
	
	if(length($a) == length($b)) {
		print "$snp\tSWITCH\n";
	}
	
	else {
		$diff = length($a) - length($b);
		
		if($diff == 1) {
			print "$snp\tSWITCH\n" unless $a =~ /$b/;
		}
		
		elsif($diff == -1) {
			print "$snp\tSWITCH\n" unless $b =~ /$a/;
		}
	}
}