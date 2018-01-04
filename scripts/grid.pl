#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$data{$data[0]}{$data[1]} = $data[2];
	$data{$data[1]}{$data[0]} = $data[2];
	
	$seen{$data[0]} = 1;
	$seen{$data[1]} = 1;
}

foreach $seen(sort keys %seen) {
	print "\t".$seen;
}

print "\n";

foreach $a(sort keys %seen) {
	print "$a";
	
	foreach $b(sort keys %seen) {
		print "\t".($data{$a}{$b} ? $data{$a}{$b} : "-");
	}
	
	print "\n";
}