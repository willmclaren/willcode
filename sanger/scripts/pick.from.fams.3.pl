#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	$dad = shift @data;
	$mum = shift @data;
	$gender = shift @data;
	$aff = shift @data;
	
	$aff = 1 if $aff == -9;
	
	push @{$kids{$fam}}, $id if (($mum > 0) && ($dad > 0) && ($aff == 2));
	
	push @{$parents{$fam}}, $id if (($mum == 0) && ($dad == 0))
}

foreach $fam(keys %kids) {

	next unless scalar @{$parents{$fam}} > 1;
	
	foreach $parent(@{$parents{$fam}}) {
		print "$parent\_A\t0\n$parent\_B\t0\n";
	}
	
	$kid = $kids{$fam}[0];
	
	print "$kid\_A\t1\n$kid\_B\t1\n";
}