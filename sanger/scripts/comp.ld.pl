#!/usr/bin/perl

%args_with_vals = (
	'x' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

if($args{'x'}) {
	open IN, $args{'x'} or die "Could not open $args{'x'}\n";
	
	while(<IN>) {
		chomp;
		$exc{(split /\t/, $_)[0]} = 1;
	}
	
	close IN;
}

our @snps, @samples;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	push @snps, $snp;
	#$snpindex{$snp} = $#snps;
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

close IN;

our @g;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	next if $exc{$sample};
	
	push @samples, $sample;
	$sampleindex = $#samples;
	
	for(1..5) { shift @data; }
	
	$s = 0;
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$g[$sampleindex][$s] = $a.$b;
		
		$s++;
	}
}


for $i(0..$#snps) {
	for $j(($i+1)..$#snps) {
		last if $chr{$snps[$i]} ne $chr{$snps[$j]};
		last if $pos{$snps[$j]} - $pos{$snps[$i]} > 250000;
		
		#$ld{$i."\t".$j} = 1 if isLD($i, $j);
		$is = isLD($i, $j);
		
		if($args{'d'}) {
			print "$snps[$i]\t$snps[$j]\t$is\n" if $is;
		}
		
		elsif($args{'l'}) {
			print "$snps[$i]\t$snps[$j]\t$is\n" unless $is;
		}
		
		else {
			"$snps[$i]\t$snps[$j]\t$is\n";
		}
	}
}
# 
# foreach $pair(keys %ld) {
# 	($a, $b) = split /\t/, $pair;
# 	print "$snps[$a]\t$snps[$b]\t$ld{$pair}\n";
# }


sub isLD {
	my ($a, $b) = @_;
	
	my %ac = ();
	my %bc = ();
	my %counts = ();
	
	for my $i(0..$#samples) {
		if(($g[$i][$a] > 0) && ($g[$i][$b] > 0)) {
			my ($x, $y) = ($g[$i][$a], $g[$i][$b]);
		
			$counts{$x}{$y}++;
			$counts{$y}{$x}++;
			
			return 0 if scalar keys %{$counts{$x}} > 1;
			return 0 if scalar keys %{$counts{$y}} > 1;
			
			$ac{$x} = 1;
			$bc{$y} = 1;
		}
	}
	
	$ret = 1;
	
	#print "$snps[$a]\t$snps[$b]\t".(scalar keys %ac)."\t".(scalar keys %bc)."\n";
	
	if((scalar keys %ac == 1) || (scalar keys %bc == 1)) {
		return 0;
	}
	
	foreach my $g(keys %counts) {
		return 0 if scalar keys %{$counts{$g}} > 1;
	}
	
	return $ret;
}