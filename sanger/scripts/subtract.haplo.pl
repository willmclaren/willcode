#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	($snp, $g) = split /\s+/, $_;
	$ref{$snp} = $g;
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	push @snps, $data[1];
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$s = '';
	
	$s .= shift @data;
	$sa = "$s\_A";
	$sb = "$s\_B";
	
	for(1..5) { $x = shift @data; $sa .= "\t$x"; $sb .= "\t$x";}
	
	foreach $snp(@snps) {
		
		$a = shift @data;
		$b = shift @data;
		
		next unless $ref{$snp};
		
		#print "$snp : $a $b\t";
		
		if($a eq $ref{$snp}) {
			$sa .= "\t$a $a";
			$sb .= "\t$b $b";
			
			#print "matched ref\tA: $a $a\tB: $b $b\n";
		}
		
		else {
			$sa .= "\t$b $b";
			$sb .= "\t$a $a";
			
			#print "don't match\tA: $b $b\tB: $a $a\n";
		}
	}
	
	print "$sa\n$sb\n";
}