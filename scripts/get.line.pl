#!/usr/bin/perl

$line = ($ARGV[0] =~ /^\d+/ ? shift @ARGV : 1);

foreach $val(split /\,/, $line) {
	@nnn = split /\-/, $val;
	
	for $a($nnn[0]..$nnn[-1]) {
		push @rpts, $a;
		$n++;
	}
}

$count = 1;

while(<>) {
	foreach $a(@rpts) {
		if($count == $a) {
			print;
			$seen++;
			last if $seen == $n;
		}
	}
	$count++;
}