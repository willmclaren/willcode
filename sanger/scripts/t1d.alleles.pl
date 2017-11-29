#!/usr/bin/perl

while(<>) {
	chomp;
	
	($sample, $dqa, $dqb1, $dqb2, $drb1, $drb2) = split /\t/, $_;
	
	$a = 0;
	$b = 0;
	
	if(($dqb1 =~ /^02/) || ($dqb2 =~ /^02/)) {
		if(($drb1 =~ /^03/) || ($drb2 =~ /^03/)) {
			$a = 1;
		}
	}
	
	if(($dqb1 =~ /^0302/) || ($dqb2 =~ /^0302/)) {
		if(($drb1 =~ /^04/) || ($drb2 =~ /^04/)) {
			$b = 1;
		}
	}
	
	print "$sample\t$a\t$b\n";
}