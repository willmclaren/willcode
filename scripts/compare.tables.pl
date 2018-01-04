#!/usr/bin/perl

open IN, shift @ARGV;

$head = <IN>;
chomp $head;
@headers_a = split /\t/, $head;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	$id = $data[4];
	
	foreach $header(@headers_a) {
		$d = shift @data;
		next if $d eq $id;
		
		$a{$id}{$header} = $d;
	}
}

close IN;



open IN, shift @ARGV;

$head = <IN>;
chomp $head;
@headers_b = split /\t/, $head;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	$id = $data[4];
	
	foreach $header(@headers_b) {
		$d = shift @data;
		next if $d eq $id;
		
		$b{$id}{$header} = $d;
	}
}

close IN;



foreach $id(keys %a) {
	next unless exists $b{$id};
	
	foreach $header(@headers_a) {
		next unless exists $b{$id}{$header};
		
		print "CMP\t$id\t$header\t$a{$id}{$header}\t$b{$id}{$header}\n";
		
		if($a{$id}{$header} ne $b{$id}{$header}) {
			print
				"MISMATCH\t$id\t$header\t".
				(length($a{$id}{$header}) >= 1 ? $a{$id}{$header} : "MISSING")."\t".
				(length($b{$id}{$header}) >= 1 ? $b{$id}{$header} : "MISSING")."\n";
		}
	}
}