#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	@data = split /\s+/, $_;
	
	shift @data if $data[0] eq "M";
	
	$snp = shift @data;
	
	$sample = 1;
	
	$size = ($size ? $size : scalar @data);
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$a{$snp}{$sample} = join "", sort ($a, $b);
		
		$sample++;
	}
}

close IN;


while(<>) {
	@data = split /\s+/, $_;
	
	shift @data if $data[0] eq "M";
	
	$snp = shift @data;
	
	next unless $a{$snp};
	
	if(scalar @data > $size) {
		@data = @data[-$size..-1];
	}
	
	$sample = 1;
	
	$null = 0;
	$match = 0;
	$mis = 0;
	%match_a = ();
	%mis_a = ();
	%obs = ();
	$total = 0;
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$g = join "", sort ($a, $b);
		$o = $a{$snp}{$sample};
		
		($oa, $ob) = sort (split //, $o);
		($ga, $gb) = sort ($a, $b);
		
# 		print "$snp\t$g\t$o\n";
		
		if($g =~ /0/ || $o =~ /0/) {
			$null++;
		}
		
		else {
			if($g eq $o) {
				$match++;
			}
			
			else {
				$mis++;
			}
			
			if($oa eq $ga) {
				$match_a{$oa}++;
			}
			
			else {
				$mis_a{$oa}++;
			}
			
			if($ob eq $gb) {
				$match_a{$ob}++;
			}
			
			else {
				$mis_a{$ob}++;
			}
			
			$obs{$oa}++;
			$obs{$ob}++;
			$total += 2;
		}
		
		$sample++;
	}
	
	$perc = 100 * ($match || $mis ? $mis / ($match + $mis) : 0);
	
	print "$snp\t$match\t$mis\t".(100-$perc)."\t$perc\t$null";
	
	foreach $a(sort {$obs{$a} <=> $obs{$b}} keys %obs) {
		$freq = ($total ? $obs{$a} / $total : 0);
		$match_a = 100 * ($match_a{$a} / $obs{$a});
		
		print "\t$a\t$freq\t$match_a";
	}
	
	print "\n";
}