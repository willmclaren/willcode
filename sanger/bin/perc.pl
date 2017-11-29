#!/usr/bin/perl

$a = 2;
$b = 3;

if(scalar @ARGV >= 2) {
	$a = shift @ARGV;
	$b = shift @ARGV;
}

$a--;
$b--;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if($data[$a] + $data[$b] > 0) {
		$perc = 100 * ($data[$b]/($data[$a]+$data[$b]));
	}

	else {
		$perc = 0;
	}
	
	print "$_\t$perc\n";
}
