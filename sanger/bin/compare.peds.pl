#!/usr/bin/perl

%args_with_vals = (
	'o' => 1,
	'l' => 1,
	's' => 1,
	'f' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# list of SNPs to include
if($args{'l'}) {
	open IN, $args{'l'} or die "Could not read from SNP list file $args{'l'}\n";
	
	while(<IN>) {
		chomp;
		
		$includelist{(split /\s+/, $_)[0]} = 1;
	}
	
	close IN;
}


# list of samples to include
if($args{'s'}) {
	open IN, $args{'s'} or die "Could not read from sample list file $args{'s'}\n";
	
	while(<IN>) {
		chomp;
		
		$includesamp{(split /\s+/, $_)[0]} = 1;
	}
	
	close IN;
}

# assumed file order
($mapa, $peda, $mapb, $pedb) = @ARGV;

# MAP FILES
###########

open IN, $mapa or die "Could not open map file for first ped file, $mapa\n";
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	elsif(scalar @data == 1) {
		$snp = $data[0];
	}
	
	else {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	push @snpsa, $snp;
}
close IN;

open IN, $mapb or die "Could not open map file for second ped file, $mapb\n";
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	elsif(scalar @data == 1) {
		$snp = $data[0];
	}
	
	else {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	push @snpsb, $snp;
}
close IN;


# get common SNP set
foreach $snp(@snpsa, @snpsb) {
	if($args{'l'}) {
		$keepsnps{$snp}++ if $includelist{$snp};
	}
	
	else {
		$keepsnps{$snp}++;
	}
}

foreach $snp(keys %keepsnps) {
	delete $keepsnps{$snp} unless $keepsnps{$snp} > 1;
}

# check we have some left
die "No SNPs found in both map files\n" unless scalar keys %keepsnps;

print "Found ".(scalar keys %keepsnps)." common SNPs\n";



# PED FILES
###########

open IN, $peda or die "Could not open first ped file, $peda\n";
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	
	$sample = ($args{'f'} ? $fam."_".$id : $fam);
	
	if($args{'s'}) {
		next unless $includesamp{$fam} || $includesamp{$sample};
	}
	
	for(1..4) { shift @data; }
	
	foreach $snp(@snpsa) {
		$a = shift @data;
		$b = shift @data;
		
		next unless $keepsnps{$snp};
		
		$a =~ tr/NACGT/01234/;
		$b =~ tr/NACGT/01234/;
		
		$g = join "", sort {$a <=> $b} ($a, $b);
		
		$genoa{$sample}{$snp} = $g;
	}
	
	# check for remaining data - suggests map file is wrong
	if((scalar @data) >= 1) {
		die "Too many genotypes in $peda (".(((scalar @data)/2) + (scalar @snpsa)).") for map file $mapa (".(scalar @snpsa)." SNPs)\n";
	}
}
close IN;

open IN, $pedb or die "Could not open second ped file, $pedb\n";
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	
	$sample = ($args{'f'} ? $fam."_".$id : $fam);
	
	if($args{'s'}) {
		next unless $includesamp{$fam} || $includesamp{$sample};
	}
	
	next unless $genoa{$sample};
	
	for(1..4) { shift @data; }
	
	foreach $snp(@snpsb) {
		$a = shift @data;
		$b = shift @data;
		
		next unless $keepsnps{$snp};
		
		$a =~ tr/NACGT/01234/;
		$b =~ tr/NACGT/01234/;
		
		$g = join "", sort {$a <=> $b} ($a, $b);
		
		$genob{$sample}{$snp} = $g;
	}
	
	# check for remaining data - suggests map file is wrong
	if((scalar @data) >= 1) {
		die "Too many genotypes in $pedb (".(((scalar @data)/2) + (scalar @snpsb)).") for map file $mapb (".(scalar @snpsb)." SNPs)\n";
	}
}
close IN;

# clean up genob
foreach $sample(keys %genob) {
	delete $genob{$sample} unless $genoa{$sample};
}

print "Found ".(scalar keys %genob)." common samples\n";


$stem = ($args{'o'} ? $args{'o'} : (split /\//, $peda)[-1]."_".(split /\//, $pedb)[-1]);

open OUT, ">".$stem.".comp.full" if $args{'f'};


foreach $sample(keys %genob) {
	foreach $snp(keys %keepsnps) {
		$a = $genoa{$sample}{$snp};
		$b = $genob{$sample}{$snp};
		
		print OUT "$sample\t$snp\t$a\t$b\t" if $args{'f'};
		
		# null
		if(($a =~ /0/) || ($b =~ /0/)) {
			$null++;
			
			$sampledist{$sample}{'null'}++;
			$snpdist{$snp}{'null'}++;
			
			print OUT "NULL" if $args{'f'};
		}
		
		# match
		elsif($a eq $b) {
			$match++;
			
			$sampledist{$sample}{'match'}++;
			$snpdist{$snp}{'match'}++;
			
			print OUT "MATCH" if $args{'f'};
		}
		
		# mismatch
		else {
			$mis++;
			
			$sampledist{$sample}{'mis'}++;
			$snpdist{$snp}{'mis'}++;
			
			if(isHet($a) || isHet($b)) {
				$type = "A";
			}
			
			else {
				$type = "B";
			}
			
			print OUT "MISMATCH_$type" if $args{'f'};
		}
		
		print OUT "\n" if $args{'f'};
	}
}


open SNP, ">$stem.comp.snps";
open SAMP, ">$stem.comp.samples";
open SUM, ">$stem.comp.summary";

print "Writing detailed reports to $stem.comp.snps and $stem.comp.samples\n";

foreach $snp(keys %snpdist) {
	$perc =
		($snpdist{$snp}{'mis'} + $snpdist{$snp}{'match'} > 0 ?
			($snpdist{$snp}{'mis'} > 0 ?
				sprintf("%.3f", 100 * ($snpdist{$snp}{'mis'} / ($snpdist{$snp}{'mis'} + $snpdist{$snp}{'match'})))
				: 0
			) : 0
		);

	print SNP
		"$snp\t".
		($snpdist{$snp}{'match'} ? $snpdist{$snp}{'match'} : 0)."\t".
		($snpdist{$snp}{'mis'} ? $snpdist{$snp}{'mis'} : 0)."\t".
		"$perc\t".
		($snpdist{$snp}{'null'} ? $snpdist{$snp}{'null'} : 0)."\n";
}
close SNP;


foreach $sample(keys %sampledist) {
	$perc =
		($sampledist{$sample}{'mis'} + $sampledist{$sample}{'match'} > 0 ?
			($sampledist{$sample}{'mis'} > 0 ?
				sprintf("%.3f", 100 * ($sampledist{$sample}{'mis'} / ($sampledist{$sample}{'mis'} + $sampledist{$sample}{'match'})))
				: 0
			) : 0
		);

	print SAMP
		"$sample\t".
		($sampledist{$sample}{'match'} ? $sampledist{$sample}{'match'} : 0)."\t".
		($sampledist{$sample}{'mis'} ? $sampledist{$sample}{'mis'} : 0)."\t".
		"$perc\t".
		($sampledist{$sample}{'null'} ? $sampledist{$sample}{'null'} : 0)."\n";
}
close SAMP;

print
	"\nSUMMARY:\n".
	"Total pairs compared: ".($null + $match + $mis)."\n".
	"Null comparisons: $null\n".
	"Valid comparisons: ".($match + $mis)." ($match matches / $mis mismatches)\n".
	"Percentage mismatches: ".($match + $mis > 0 ? sprintf("%.3f", (100 * ($mis / ($match + $mis)))) : 0)."\%\n";
	
	
print SUM
	"SUMMARY:\n".
	"A) $peda\nB) $pedb\n\n".
	"Total pairs compared: ".($null + $match + $mis)."\n".
	"Null comparisons: $null\n".
	"Valid comparisons: ".($match + $mis)." ($match matches / $mis mismatches)\n".
	"Percentage mismatches: ".($match + $mis > 0 ? sprintf("%.3f", (100 * ($mis / ($match + $mis)))) : 0)."\%\n";
	
	



sub isHet {
	my $g = join "", @_;
	
	my $ret = 1;
	$ret = 0 if substr($g,0,1) eq substr($g,1,1);
	return $ret;
}