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
	
	push @{$kids{$fam}{$aff}}, $id;
}

foreach $fam(keys %kids) {

	next unless scalar keys %{$kids{$fam}} > 1;
	
	foreach $aff(1,2) {
	
		$num = scalar @{$kids{$fam}{$aff}};
		
		$pick = int(rand ($num - 1));
		
		print $kids{$fam}{$aff}[$pick]."\_A\t".($aff-1)."\n".$kids{$fam}{$aff}[$pick]."\_B\t".($aff-1)."\n";
	}
}