#!/usr/bin/perl

$col = shift @ARGV;

die "First argument must be a numerical column\n" unless $col =~ /^\d+$/;

$col--;

$new = shift @ARGV;

die "Second argument must be a replacement column\n" if $new eq '';

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$data[$col] = $new;
	
	print (join "\t", @data);
	print "\n";
}
