#!/usr/bin/perl

while(<>) {
	if(!$active) {
		$active = 1 if /BEGIN GENOTYPES/;
	}
	
	else {
		chomp;
		$s = $_;
		
		print "$s\t1\t0\t0\t0\t0";
		
		$a = <>;
		$b = <>;
		
		@a = split /\s+/, $a;
		@b = split /\s+/, $b;
		
		die "Number of genotypes does not match\n" unless scalar @a == scalar @b;
		
		while(@a) {
			print "\t".(shift @a)." ".(shift @b);
		}
		
		print "\n";
	}
}