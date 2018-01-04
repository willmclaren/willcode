#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$i++;
	print
		"$i\t$data[0]\t1\t1\t".
		($data[4] ? $data[4] : 9)."\t".
		($data[5] == 2 ? "Case" : $data[5] == 1 ? "Control" : "Unknown").
		"\t1";
	
	for(1..6) {
		shift @data;
	}
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		print "\t$a $b";
	}
	
	print "\n";
}