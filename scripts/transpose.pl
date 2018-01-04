#!/usr/bin/perl

$row = 0;

while(<>){
	chomp;
	
	@data = split /\t/, $_;
	
	for $col(0..($#data)) {
		$array[$col][$row] = $data[$col];
	}
	
	$row++;
}


foreach $row(@array) {
	@row = @$row;

	print (join "\t", @row);
	print "\n";
}
