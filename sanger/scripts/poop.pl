#!/usr/bin/perl

for $i(1..5) {
	@list = ();	

	for $j($i..($i+4)) {
		$k = ($j > 5 ? $j - 5 : $j);
		$l = ($k - ($i -1));
		$l = ($l < 1 ? $l +5 : $l);
		
		push @list, "CEU.JPT\+CHB.$k.f$l.g";
	}
	
	system "cat @list | list.grep.pl ../SNPS.TO.INCLUDE > CHB.data.$i.g";
}