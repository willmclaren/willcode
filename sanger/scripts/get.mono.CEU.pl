#!/usr/bin/perl

@pop_order = qw/CEU CHB JPT YRI CHB+JPT/;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$snp = shift @data;
	
	foreach $pop(@pop_order) {
		$a = shift @data;
		$f_a = shift @data;
		
		$b = shift @data;
		$f_b = shift @data;
		
		$maf = $f_a;
		$ma = $a;
		$maf = $f_b if $f_b < $f_a;
		$ma = $b if $f_b < $f_a;
		
		$freq{$pop} = $maf;
	}
	
	print "$snp\t$freq{'CEU'}\t$freq{'CHB'}\t$freq{'JPT'}\t$freq{'YRI'}\t$freq{'CHB+JPT'}\n";# if $freq{'CEU'} == 0;
}