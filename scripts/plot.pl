#!/usr/bin/perl

open OUT, ">.$$.plot.temp";
while(<>) {
	print OUT $_;
}
close OUT;

open TEMP, ">.$$.plot.prog";
print TEMP "plot \".$$.plot.temp\" using 1\:2\npause 10";
close TEMP;

system("gnuplot .$$.plot.prog");

system("rm .$$\*");