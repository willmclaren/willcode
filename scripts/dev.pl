#!/usr/bin/perl

use strict;

my @alleles;
my @geno;
my @samples;
my $string;

while(<>) {
	chomp;
	
	my @data = split /\s+/, $_;
	
	push @samples, shift @data;
	
	for(1..5) { shift @data;}
	
	my @temp = ();
	my $a, $b;
	my $n = 0;
	my $code = 0;
	$string = '';
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		if(isNull($a, $b)) {
			$code = 0;
		}
		
		elsif(isHet($a, $b)) {
			$code = 2;
		}
		
		elsif($alleles[$n]) {
			if($alleles[$n] eq $a) {
				$code = 1;
			}
			
			else {
				$code = 3;
			}
		}
		
		else {
			$alleles[$n] = $a;
			$code = 1;
		}
		
		push @temp, $code;
		$string .= "a";
	
		$n++;
	}
	
	push @geno, pack($string, @temp);
}


for my $i(0..$#geno) {
	print "$samples[$i]\t1\t0\t0\t0\t0\t";
	print (join "\t", unpack($string, $geno[$i]));
	print "\n";
}


sub isHet {
	my $g = join "", @_;
	
	my $ret = 1;
	$ret = 0 if substr($g,0,1) eq substr($g,1,1);
	return $ret;
}

sub isNull {
	my $g = join "", @_;
	
	my $ret = 0;
	$ret = 1 if $g =~ /n|0|\-9/i;
	return $ret;
}