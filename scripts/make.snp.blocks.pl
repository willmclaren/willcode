#!/usr/bin/perl

$thresh = 500000;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	($snp, $chr, $pos) = ($data[0], $data[1], $data[2]);
	
	if(($chr == $prev_chr) && ($pos - $prev_pos < $thresh) && (scalar @cluster)) {
		$end = $pos;
		
		push @cluster, $snp;
	}
	
	elsif(scalar @cluster >= 2) {
		print $prev_chr."\t".$start."\t".$end."\t".(join ",", @cluster)."\n";
		
		@cluster = ();
		$start = $pos;
		push @cluster, $snp;
	}
	
	else {
		@cluster = ();
		$start = $pos;
		push @cluster, $snp;
	}
	
	$prev_chr = $chr;
	$prev_pos = $pos;
}

if(scalar @cluster >= 2) {
	print $prev_chr."\t".$start."\t".$end."\t".(join ",", @cluster)."\n";
}