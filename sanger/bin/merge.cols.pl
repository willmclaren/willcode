#!/usr/bin/perl

$col_a = shift @ARGV;
$col_b = shift @ARGV;

$col_a--;
$col_b--;

die "Incorrect column numbers supplied" unless $col_a =~ /\d+/ && $col_b =~ /\d+/;

while(<>) {
	@data = split /\t/, $_;

	$merged = $data[$col_a].$data[$col_b];

	$data[$col_a] = $merged;

	splice(@data, $col_b, 1);

	print (join "\t", @data);
}
