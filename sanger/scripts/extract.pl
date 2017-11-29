#!/usr/bin/perl

while(<>) {
	chomp;
	
	@rhian = ();
	@lude = ();
	
	# rs ID
	$rs = $_;
	
	next unless $rs =~ /rs/;
	
	# chrom and pos
	$c_p = <>;
	($crap, $chrom, $pos, $crapp) = split /\s+/, $c_p;
	$chrom =~ s/\,//g;
	
	for(1..9) {
		$crap = <>;
	}
	
	for(1..9) {
		$num = <>;
		chomp $num;
		push @rhian, $num;
	}
	
	for(1..2) {
		$crap = <>;
	}
	
	for(1..9) {
		$num = <>;
		chomp $num;
		push @lude, $num;
	}
	
	$crap = <>;
	
	print "$rs\t$chrom\t$pos\t";
	print (join "\t", @rhian);
	print "\t";
	print (join "\t", @lude);
	print "\n";
}