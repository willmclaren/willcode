#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use Statistics::Basic::Correlation;


while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$id = shift @data unless scalar @data < 3;
	
	$a = shift @data;
	$b = shift @data;
	
	push @a, $a;
	push @b, $b;
}

$c = new Statistics::Basic::Correlation(\@a, \@b);
print $c->query;
print "\n";
