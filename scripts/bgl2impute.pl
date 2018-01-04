#!/usr/bin/perl

open P, ">phased";
open L, ">legend";

print L "rs position X0 X1\n";

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	shift @data;
	$snp = shift @data;
	
	%seen = ();
	%back = ();
	$num = 1;
	foreach $item(@data) {
		unless($seen{$item}) {
			$seen{$item} = $num;
			$back{$num} = $item;
			$num++;
		}
	}
	
	die "Too many items for $snp\n" if scalar keys %seen > 2;
	
	$first = 1;
	
	foreach $item(@data) {
		print P ($first ? "" : " ").($seen{$item} - 1);
		$first = 0;
	}
	
	print L "$snp $back{'1'} ".($back{'2'} ? $back{'2'} : "?")."\n";
	
	print P "\n";
}