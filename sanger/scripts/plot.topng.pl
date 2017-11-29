#!/usr/bin/perl

open OUT, ">.$$.plot.temp";
while(<>) {
	print OUT $_;
}
close OUT;

open TEMP, ">.$$.plot.prog";
print TEMP 
	"set terminal png nocrop enhanced size 640,480\n".
	"set xlabel \"Position\"\nset ylabel \"-log(p)\"\nset yrange [0:8]\n".
	"plot \".$$.plot.temp\" using 1\:2\n";
close TEMP;

open PIPE, "gnuplot .$$.plot.prog |";
while(<PIPE>) {
	print;
}
close PIPE;

system("rm .$$\*");