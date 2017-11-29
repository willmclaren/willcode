#!/usr/bin/perl

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

open IN, shift @ARGV;

#print "Reading in pairs\n";

while(<IN>) {
	chomp;
	
	push @pairs, $_;
	
	($a, $b) = split /\t/, $_;
	$inpairs{$a} = 1;
	$inpairs{$b} = 1;
}

close IN;


open IN, shift @ARGV;

#print "Reading SNP info\n";

while(<IN>) {
	chomp;
	
	if($args{'p'}) {
		($chr, $snp, $crap, $pos) = split /\t/, $_;
	}
	else {
		($snp, $chr, $pos) = split /\t/, $_;
	}
	
	push @order, $snp;
}

close IN;


#print "Reading data\n";

# $file = shift @ARGV;
# open IN, $file;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	if($args{'p'}) {
		for(1..5) {
			shift @data;
		}
	}
	
	$snpnum = 0;
	
	%geno = ();
	
	while(@data) {
		if($args{'p'}) {
			$geno = shift @data;
			$geno .= shift @data;
		}
		
		else {
			$geno = shift @data;
		}
		$snp = $order[$snpnum++];
		
		next unless $inpairs{$snp};
		
		$geno{$snp} = $geno;
	}
	
	foreach $pairnum(0..$#pairs) {
		($a, $b) = split /\t/, $pairs[$pairnum];
	
		$pair_geno{$pairnum}{$geno{$a}."\t".$geno{$b}}++;
	}
}

close IN;


#print "Output:\n";

foreach $pairnum(0..$#pairs) {
	($a, $b) = split /\t/, $pairs[$pairnum];
	
	#print "\n> $a $b\n";
	
	foreach $geno(keys %{$pair_geno{$pairnum}}) {
		print "$a\t$b\t$geno\t$pair_geno{$pairnum}{$geno}\n";
	}
}