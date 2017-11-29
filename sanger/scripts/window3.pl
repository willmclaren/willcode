#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	$list{(split /\t/, $_)[0]} = 1;
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	next if /OMNIBUS/;
	next unless $list{$data[0]};
	
	$data{$data[0]}{$data[1]}{'p'} = $data[6];
	$data{$data[0]}{$data[1]}{'fa'} = $data[2];
	$data{$data[0]}{$data[1]}{'fb'} = $data[3];
}

foreach $win(keys %data) {
	$min = (sort {$data{$win}{$a}{'p'} <=> $data{$win}{$b}{'p'}} keys %{$data{$win}})[0];
	
	print "$win\t$data{$win}{$min}{'fa'}\t$data{$win}{$min}{'fb'}\n";
}