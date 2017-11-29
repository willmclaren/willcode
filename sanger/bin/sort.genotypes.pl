#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	for $i(0..$#data) {
		$g = $data[$i];
		
		if((length $g == 2) && ($g =~ /[ACGT][ACGT]/)) {
			$data[$i] = join "", sort (split //, $data[$i]);
		}
	}
	
	print (join "\t", @data);
	print "\n";
}