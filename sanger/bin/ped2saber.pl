#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	push @poslist, $data[-1];
}
close IN;

# header
print join " ", @poslist;
print "\n";

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	for(1..6) { shift @data; }
	
	$i = 0;
	$first = 1;
	
	while(@data) {
		$i++;
		$a = shift @data;
		$b = shift @data;
		
		if($a =~ /0|n/i || $b =~ /0|n/i) {
			$val = -99;
		}
		
		elsif(defined $vals{$i}{$a.$b}) {
			$val = $vals{$i}{$a.$b};
		}
		
		elsif($a ne $b) {
			$val = 1;
		}
		
		elsif(scalar keys %{$vals{$i}} >= 1) {
			$val = 2;
			$vals{$i}{$a.$b} = 2;
		}
		
		else {
			$val = 0;
			$vals{$i}{$a.$b} = 0;
		}
		
		print ($first ? "" : " ");
		print $val;
		
		$first = 0 if $first;
	}
	
	print "\n";
}