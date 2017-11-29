#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	$windows{(split /\t/, $_)[0]} = 1;
}

close IN;



while(<>) {
	chomp;
	@data = split /\t/, $_;
	next unless $windows{$data[0]};
	next if /OMNIBUS/;
	
	$data{$data[0]}{$data[1]}{"p"} = $data[6];
	$data{$data[0]}{$data[1]}{"fa"} = $data[2];
	$data{$data[0]}{$data[1]}{"fb"} = $data[3];
}

foreach $window(keys %data) {
	$min = (sort {$data{$window}{$a}{"p"} <=> $data{$window}{$b}{"b"}} keys %{$data{$window}})[0];
	print "$window\t$data{$window}{$min}{'fa'}\t$data{$window}{$min}{'fb'}\n";
}