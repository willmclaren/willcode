#!/usr/bin/perl

# SNPS A
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @a, (split /\s+/, $_)[0];
}

close IN;


# SNPS B
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @b, (split /\s+/, $_)[0];
}

close IN;



# BLOCKS A
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	if(/BLOCK/) {
		@data = split /\s+/, $_;
		
		$ablock = $data[1];
		
		print "$_\n";
	}
	
	$in = '';
	
	while($in !~ /Multi/i) {
		$in = <IN> || last;
		
		print $in;
	}
}
close IN;

print "Multiallelic dprime or something\n";


# BLOCKS B
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	if(/BLOCK/) {
		@data = split /\s+/, $_;
		
		$data[1] += $ablock;
		
		for $i(3..$#data) {
			$data[$i] += (scalar @a);
		}
		
		print (join " ", @data);
		print "\n";
	}
	
	$in = '';
	
	while($in !~ /Multi/i) {
		$in = <IN> || last;
		
		print $in;
	}
}
close IN;