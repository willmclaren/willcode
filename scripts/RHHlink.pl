#!/usr/bin/perl

$args{'t'} = 0.01;
$args{'o'} = "RHHlink";
$args{'r'} = 5000000;

%args_with_vals = (
	't' => 1,
	's' => 1,
	'c' => 1,
	'o' => 1,
	'p' => 1,
	'r' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}



$snpfile = shift @ARGV;
open IN, $snpfile or die "Could not read from SNP file $snpfile\n";

debug("Reading SNP info from $snpfile");

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	if(scalar @split == 3) {
		($snp, $chr, $pos) = @split;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @split;
	}
	
	push @order, $snp;
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
	
	$havesnp{$snp} = 1;
}

close IN;

debug("Read data for ".(scalar @order)." SNPs");


open IN, $args{'p'} or die ($args{'p'} ? "Pairs file not specified - use -p [pairs_file]\n" : "Could not open pairs file $args{'p'}\n");

debug("Reading pairs file $args{'p'}");

while(<IN>) {
	chomp;
	
	($a, $b) = split /\s+/, $_;
	
	next unless ($havesnp{$a} && $havesnp{$b});
	
	push @pairs, $_;
	
	$inpairs{$a} = 1;
	$inpairs{$b} = 1;
}

close IN;

debug((scalar @pairs)." pairs found");

$pedfile = shift @ARGV;
open IN, $pedfile or die ($pedfile ? "Ped file not specified\n" : "Could not read from ped file $pedfile\n");

debug("Reading data from ped file $pedfile");

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	# sample ID in first column
	$sample = shift @data;
	
	# skip next 5 columns
	for(1..5) {
		shift @data;
	}
	
	$snpnum = 0;
	
	%geno = ();
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$geno = join "", sort ($a, $b);
		
		$snp = $order[$snpnum];
		$snpnum++;
		
		next unless $inpairs{$snp};
		
		$geno{$snp} = $geno;
	}
	
	foreach $pairnum(0..$#pairs) {
		($a, $b) = split /\s+/, $pairs[$pairnum];
	
		$pair_geno{$pairnum}{$geno{$a}." ".$geno{$b}}++;
	}
}

close IN;


foreach $pairnum(keys %pair_geno) {
	($a, $b) = split /\s+/, $pairs[$pairnum];
	
	foreach $geno(keys %{$pair_geno{$pairnum}}) {
		next if $geno =~ /0|N/i;
		
		($ga, $gb) = split /\s+/, $geno;
		
		#print "$a $b $ga $gb $pair_geno{$pairnum}{$geno}\n";
		
		$counts{$a." ".$b}{$ga." ".$gb} = $pair_geno{$pairnum}{$geno};
		$totals{$a." ".$b} += $pair_geno{$pairnum}{$geno};
		
		$present{$a} = 1;
		$present{$b} = 1;
	}
}


debug("Calculating rare status for LD pairs");

open OUT, ">".$args{'o'}."_pairs.dist";

foreach $pair(keys %counts) {
	($snpa, $snpb) = split / /, $pair;
	
	%homs = ();

	# resolve hets and get hom info
	foreach $geno(keys %{$counts{$pair}}) {
		$rare = 0;
		
		($genoa, $genob) = split / /, $geno;
		
		$hets = 0;
		$hets++ if isHet($genoa);
		$hets++ if isHet($genob);
		
		# if both are hets, assume OK
		
		# if only one is het, pair must be discordant
		if($hets == 1) {
			$rare{$snpa}{$snpb}{$geno} = 1;
		}
		
		# if both are homs, store count for checking in next step
		else {
			$homs{$geno} = $counts{$pair}{$geno};
		}
		#$rare{$snpa}{$snpb}{$geno} = 1 if ($counts{$pair}{$geno} / $totals{$pair}) <= $args{'t'};
	}
	
	
	# now resolve homs
	if(scalar keys %homs > 1) {
		@homorder = sort {$homs{$b} <=> $homs{$a}} keys %homs;
		
		# check that we don't have matching counts
		unless($homs{$homorder[0]} == $homs{$homorder[1]}) {
			
			# find the most common pair of homs
			($comma, $commb) = split / /, $homorder[0];
		
			foreach $i(1..$#homorder) {
				($a, $b) = split / /, $homorder[$i];
				
				# must be discordant if either genotype has already been seen in the most common pair
				$rare{$snpa}{$snpb}{$homorder[$i]} = 2 if (($a eq $comma) or ($b eq $commb));
			}
		}
	}
	
	# print out pairs dist info
	foreach $geno(keys %{$counts{$pair}}) {
		print OUT
			"$pair\t$geno\t$counts{$pair}{$geno}\t".
			($counts{$pair}{$geno} / $totals{$pair})."\t".
			($rare{$snpa}{$snpb}{$geno} ? $rare{$snpa}{$snpb}{$geno} : 0)."\n";
	}
}

close OUT;

return 0 if $args{'po'};


open IN, $pedfile or die ($pedfile ? "Ped file not specified\n" : "Could not read from ped file $pedfile\n");

debug("Re-reading data from ped file $pedfile");

open FULL, ">".$args{'o'}."_full.dist";
open OUT, ">".$args{'o'}."_sample.dist";

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	# sample ID in first column
	$sample = shift @data;
	
	# skip next 5 columns
	for(1..5) {
		shift @data;
	}
	
	$num = 0;
	%geno = ();
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$geno = join "", sort ($a, $b);
		$snp = $order[$num];
		$num++;
		
		next unless $present{$snp};
		
		$geno{$snp} = $geno;
	}
	
	die "No genotypes recorded\n" unless scalar keys %geno > 1;
	
	$null = 0;
	$right = 0;
	$wrong = 0;
	%counts = ();
	
	foreach $a(keys %rare) {
		foreach $b(keys %{$rare{$a}}) {
		
			if(($geno{$a} !~ /a|c|g|t|1|2|3|4/i) || ($geno{$b} !~ /a|c|g|t|1|2|3|4/i)) {
				$null++;
				
				print FULL "$sample\t$a\t$b\t"."NULL\n" if $args{'ff'};
			}
			
			elsif($rare{$a}{$b}{$geno{$a}." ".$geno{$b}}) {
				$wrong++;
				
				print FULL "$sample\t$a\t$b\t"."WRONG\n";
				
				# get the midpoint of the two SNPs
				$mid = ($pos{$b} + $pos{$a})/2;
				$region = $chr."_".(int ($mid / $args{'r'}));
				
				$counts{$region}++;
			}
			
			else {
				$right++;
				
				print FULL "$sample\t$a\t$b\t"."RIGHT\n" if $args{'ff'};
			}
		}
	}
	
	$none = 0;
	$low = 0;
	$mid = 0;
	$high = 0;
	$total = 0;
	
	foreach $region(keys %counts) {
		if($counts{$region} <= 1) {
			$low += $counts{$region};
		}
		
		elsif($counts{$region} <= 3) {
			$mid += $counts{$region};
		}
		
		else {
			$high += $counts{$region};
		}
		
		$total += $counts{$region}
	}
	
	print OUT
		"$sample\t$right\t$wrong\t$null\t".
		(($wrong || $right) ? (100*$wrong/($right+$wrong)) : 0)."\t".
		($total ? ($high/$total)*100 : 0)."\n";
}

debug("Done");

close IN;






# GET CURRENT DATE AND TIME IN SQL FORMAT
#########################################

sub getTime() {
	my @time = localtime(time());

	# increment the month (Jan = 0)
	$time[4]++;

	# add leading zeroes as required
	for my $i(0..4) {
		$time[$i] = "0".$time[$i] if $time[$i] < 10;
	}

	# put the components together in a string
	my $time =
# 		($time[5] + 1900)."-".
# 		$time[4]."-".
# 		$time[3]." ".
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime;
	my $pid = $$;
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
}


# CHECK HET STATUS SUBROUTINE
#############################

sub isHet {
	my $g = join "", @_;
	
	my $ret = 1;
	$ret = 0 if substr($g,0,1) eq substr($g,1,1);
	return $ret;
}