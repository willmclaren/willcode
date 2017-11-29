#!/usr/bin/perl

# load block definitions
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($id, $block) = split /\t/, $_;
	
	$start = (split /\,/, $block)[0];
	
	$blocks{$id}{'block'} = $block;
	$blocks{$id}{'start'} = $start;
}

close IN;


# parse data
while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	$sample = $data[0];
	%output = ();
	
	foreach $id(sort {$blocks{$a}{'start'} <=> $blocks{$b}{'start'}} keys %blocks) {	
		$geno = '';
	
		foreach $marker(split /\,/, $blocks{$id}{'block'}) {
			$geno .= $data[$marker];
		}
		
		$output{$id} = $geno;
	}
	
	$line_b = <>;
	chomp $line_b;
	
	@data = split /\s+/, $line_b;
	$sample_b = $data[0];
	
	die "Incorrect file format\n" unless $sample eq $sample_b;
	
	foreach $id(sort {$blocks{$a}{'start'} <=> $blocks{$b}{'start'}} keys %blocks) {
		$geno_b = '';
	
		foreach $marker(split /\,/, $blocks{$id}{'block'}) {
			$geno_b .= $data[$marker];
		}
		
		$output{$id} .= ','.$geno_b;
	}
	
	
	foreach $block(sort {$blocks{$a}{'start'} <=> $blocks{$b}{'start'}} keys %output) {
		print "$block\t$sample\t$output{$block}\t1\n";
	}
}