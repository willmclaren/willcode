#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$print = 1;
	
	if($data[4] eq '?' or $data[6] eq '?') {
		$print = 0 if $data[3] eq $data[5];
		
		if($data[6] eq '?') {
			$a = $data[4];
			$a =~ tr/ACGT/TGCA/;
			$data[6] = $a;
		}
	}
	
	if((join "", sort ($data[3], $data[5])) eq (join "", sort ($data[4], $data[6]))) {
		$print = 0;
	}
	
	if($data[3] eq $data[5] and $data[4] eq $data[6]) {
		$print = 0;
	}
	
	if($print) {
		print (join "\t", @data);
		print "\n";
	}
}