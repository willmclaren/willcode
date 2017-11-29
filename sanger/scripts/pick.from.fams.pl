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
	
	print "$id\_A\t0\n$id\_B\t0\n" if (($dad == 0) && ($mum == 0) && ($aff < 2));
	
# 	if($id eq "12916902") {
# 		print "$id\t$dad\t$mum\t$aff\n";
# 	}
# 	
	push @{$kids{$fam}}, $id if (($aff == 2) && ($dad > 0) && ($mum > 0));
}

foreach $fam(keys %kids) {
	$num = scalar @{$kids{$fam}};
	
	$pick = int(rand ($num - 1));
	
	print $kids{$fam}[$pick]."\_A\t1\n".$kids{$fam}[$pick]."\_B\t1\n";
}