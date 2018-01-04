#!/usr/bin/perl

# first read in the map file
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	push @markers, $split[(scalar @split > 3 ? 1 : 0)];
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$id = (length($data[1]) > 1 ? $data[1] : $data[0]);
	
	for(1..6) {
		shift @data;
	}
	
	$num = 0;
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$geno = $a.$b;
		
		$geno =~ tr/01234/NACGT/;
		
		$geno = join "", (sort (split //, $geno));
	
		$marker = $markers[$num];
		
		print "$marker\t$id\t$geno\t1\n";
		
		$num++;
	}
}