#!/usr/bin/perl

$header = <>;
chomp $header;
@header = split /\s+/, $header;
shift @header;

open OUT, ">debug";

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	push @samples, $sample;
	
	foreach $head(@header) {
		$a = shift @data;
		
		$data{$head}{$sample} = $a;
		
		#print OUT "$a\t$seen{$head}{$a}\n";
		
		#print OUT "SKIPPY THE GODDAMN BUSH KANGAROO\n" if $a eq '-';
		next if $a =~ /\-/;
		$seen{$head}{$data{'Cohort'}{$sample}}{$a} = 1;
	}
}

HEAD: foreach $head(@header) {
	next if $head =~ /Cohort/;
	next if $head =~ /status/;
	
	%coh = ();
	$total = 0;
	
	foreach $cohort(keys %{$seen{$head}}) {
		$num = scalar keys %{$seen{$head}{$cohort}};
		$coh{$cohort} = $num if $num >= 1;
		$total += $num;
	}
	
	$skip{$head} if $total < 3;
	$skip{$head} if scalar keys %coh < 2;
	
	print OUT "$head $total %coh\n";
	
# 	$skip{$head} = 1 if scalar keys %{$seen{$head}} < 2;
# 	
# 	print OUT "$head has ".(scalar keys %{$seen{$head}})." levels : ".(join "\,", keys %{$seen{$head}})."\n";
}

print "Sample";

for $i(0..2) {
	print "\t".$header[$i];
}

for $i(3..$#header) {
	print "\t".$header[$i] unless $skip{$header[$i]};
}

print "\n";

foreach $sample(@samples) {
	print $sample;

	for $i(0..2) {
		print "\t".$data{$header[$i]}{$sample};
	}
	
	for $i(3..$#header) {
		print "\t".$data{$header[$i]}{$sample} unless $skip{$header[$i]};
	}
	
	print "\n";
}