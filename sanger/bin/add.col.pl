#!/usr/bin/perl

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;

	if($arg =~ /e/) {
		$end = 1;
	}
	
	if($arg =~ /i/) {
		$inc = 1;
	}
}

$text = shift @ARGV;

while(<>) {
	if($end) {
		chomp;
		print "$_\t$text\n";
	}
	
	else {
		print "$text\t$_";
	}
	
	$text++ if $inc;
}