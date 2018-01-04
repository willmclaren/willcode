#!/usr/bin/perl

if($ARGV[0] =~ /\-a/i) {
	shift @ARGV;
	$ag = 1;
}

if($ARGV[0] =~ /\-n/i) {
	shift @ARGV;
	$n = 1;
}

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	print shift @data;
	
	for(1..5) {
		print "\t".(shift @data);
	}
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		if($a =~ /\d/) {
			($c, $d) = sort {$a <=> $b} ($a, $b);
		}
		
		else {
			($c, $d) = sort ($a, $b);
		}
		
		$g = $c." ".$d;
		
		if($ag) {
			$g =~ tr/01234/NACGT/;
		}
		
		if($n) {
			$g =~ tr/NACGT/01234/;
		}
		
		print "\t$g";
	}
	
	print "\n";
}