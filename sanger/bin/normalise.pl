#!/usr/bin/perl

$file = shift @ARGV;
open IN, $file or die;

while(<IN>) {
	next if /SNP/;

	chomp;
	
	@data = split /\t/, $_;
	
	$a = $data[4];
	$b = $data[6];
	
	$maxa{$data[0]} = $a if $a > $maxa{$data[0]};
	$maxb{$data[0]} = $b if $b > $maxb{$data[0]};
}

close IN;

open IN, $file or die;

while(<IN>) {
	if(/SNP/) {
		print;
	}
	
	else {
		chomp;
		@data = split /\t/, $_;
		
		$data[4] /= $maxa{$data[0]};
		$data[6] /= $maxb{$data[0]};
		
		print (join "\t", @data);
		print "\n";
	}
}