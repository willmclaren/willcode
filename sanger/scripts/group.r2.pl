#!/usr/bin/perl

while(<>) {
	chomp;
	
	($a, $b, $r) = split /\t/, $_;
	
	$r{$a}{$b} = $r;
	$r{$b}{$a} = $r;
}

$group_num = 1;

foreach $a(keys %r) {
	$in = 0;

	foreach $group(keys %groups) {
		if($groups{$group}{$a}) {
			$in = $group;
			last;
		}
	}
	
	if(!$in) {
		$groups{$group_num}{$a} = 1;
		$in = $group_num;
		$group_num++;
	}
	
	foreach $b(keys %{$r{$a}}) {
		$groups{$in}{$b} = 1;
	}
}

foreach $group(sort {$a <=> $b} keys %groups) {
	next unless scalar keys %{$groups{$group}} > 2;

	foreach $snp(keys %{$groups{$group}}) {
		print "$snp\t$group\n";
	}
}