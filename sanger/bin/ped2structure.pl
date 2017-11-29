#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	push @poslist, $data[-1];
	push @snplist, $data[(scalar @data == 3 ? 0 : 1)];
}
close IN;

# header
print join " ", @snplist;
print "\n";

$first = 1;
for $i(0..$#poslist) {
	if($first) {
		$first = 0;
	}
	
	else {
		print " ";
	}

	print (defined $poslist[$i+1] ? $poslist[$i+1] - $poslist[$i] : 0);

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$id = $data[0];
	$phen = $data[5];
	
	print "$id 0 0 $phen";
	
	for(1..6) { shift @data; }
	
	$i = 0;
	
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
		
		print " ".$val;
	}
	
	print "\n";
}