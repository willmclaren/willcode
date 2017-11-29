#!/usr/bin/perl

# USAGE
#######

$usage =<<END;
Usage: perl getRareHets.pl [options] genotype_data_file

-----------------------------------------------------------

List of options requiring an argument:
	
	-s	File containing SNP information
	-d	Distance threshold for SNP blocks (basepairs)
	-g	Load a genotype distribution from a file instead of calculating it
	-rhm	Fraction threshold for hom genotype frequency
	-rht	Fraction threshold for het genotype frequency
	-o	Stem for output files
	-e	List of samples to exclude from analysis

-----------------------------------------------------------
			
List of options without an argument (i.e. flags)
	
	-ns	If specified, SNP distribution won't be exported
	-nm	If specified, sample distribution won't be exported
	-ng	If specified, genotype counts won't be exported
	-nht	Don't examine rare hets
	-nhm	Don't examine rare homs
	-full	Write out full list of which SNPs contribute counts to each sample
END

# if no arguments have been given, give a usage message
if($ARGV[0] !~ /^\-/) {
	die $usage;
}

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
%args_with_vals = (
	's' => 1,
	'd' => 1,
	'l' => 1,
	'rhm' => 1,
	'rht' => 1,
	'o' => 1,
	'g' => 1,
	'e' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
		
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# die if user has specified that neither homs nor hets should be investigated
if($args{'nhm'} && $args{'nht'}) {
	die "Cannot use both -nht and -nhm\n\n".$usage;
}

# set thresholds
$het_frac = ($args{'rht'} ? $args{'rht'} : 0.02);
$hom_frac = ($args{'rhm'} ? $args{'rhm'} : 0.005);
$dist_thresh = ($args{'d'} ? $args{'d'} : 1000000);

debug("Looking for rare homs with using het frequency of $hom_frac") unless $args{'nhm'};
debug("Looking for rare hets with frequency less than $het_frac") unless $args{'nht'};
debug("Eliminating SNPs closer than $dist_thresh bp") if $args{'s'};


# READ LIST OF SNPS IF GIVEN
############################

if($args{'l'}) {
	open IN, $args{'l'} or die "Could not open SNP list file $args{'l'}\n";
	
	debug("Reading list of SNPs to include from ".$args{'l'});
	
	while(<IN>) {
		chomp;
		
		$snplist{(split /\t/, $_)[0]} = 1;
	}
	
	close IN;
}

# READ SNP INFO IF GIVEN
########################

if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	debug("Reading SNP info from ".$args{'s'});

	while(<IN>) {
		chomp;
		
		next unless /\d/;
		
		($snp, $chrom, $pos) = split /\t/, $_;
		
		$snps{$snp}{'chr'} = $chrom;
		$snps{$snp}{'pos'} = $pos;
	}
	
	close IN;
}


# READ LIST OF SAMPLES TO EXCLUDE IF GIVEN
##########################################

if($args{'e'}) {
	open IN, $args{'e'} or die "Could not open excluded list $args{'e'}\n";
	
	debug("Reading list of samples to exclude from ".$args{'e'});
	
	while(<IN>) {
		chomp;
		
		$exclude{$_} = 1;
	}
	
	close IN;
}


# main data file	
@files = @ARGV;

# IF THERE IS ALREADY A GENOTYPE DISTRIBUTION
#############################################

if($args{'g'}) {
	open IN, $args{'g'} or die "Could not open genotype distribution $args{'g'}\n";
	
	debug("Reading genotype distribution from ".$args{'g'});
	
	if(!$args{'ng'}) {
		open OUT, ">".($args{'o'} ? $args{'o'}.'_' : '')."genotype.dist";
		print OUT "SNP\tCount(m)\tCount(h)\tCount(M)\tCount(-)\tMinor\tHet\tMajor\trareHet\trareHom\n";
		
		debug("Writing genotype counts to ".($args{'o'} ? $args{'o'}.'_' : '')."genotype.dist");
	}
	
	while(<IN>) {
		next unless /\d/;
		
		chomp;
		
		($snp, $minorc, $hetc, $majorc, $no, $minor, $het, $major, $isHet, $isHom) = split /\t/, $_;
		
		if(scalar keys %snplist) {
			next unless $snplist{$snp};
		}
		
		$minorc = 0 unless $minorc;
		$hetc = 0 unless $hetc;
		$majorc = 0 unless $majorc;
		
		$total = $minorc + $hetc + $majorc;
		
		#print "$snp\t$minorc\t$hetc\t$majorc\n";
		
		# identify rare hets
		if(($hetc > 0) && (!$args{'nht'}) && ($hetc / $total <= $het_frac) && ($minorc == 0)) {
			$hets{$snp} = $hetc;
		
			$hetcont{$hetc}{$snp} = 1;
			
			#print "$snp\t$minorc\t$hetc\t$majorc\t$total\t".($hetc / $total)."\n";
		}
		
		# identify rare homs method 1
 		if(
 			$minorc &&
 			(!$args{'nhm'}) && 
 			($minorc / $total <= $hom_frac) && 
 			($hetc / $total <= $het_frac)
 		) {
 			$homs{$snp} = $minorc;
 			
 			$homcont{$minorc}{$snp} = 1;
 			
 			$minorhoms{$snp} = $minor;
  		}

		print OUT 
			"$snp\t$minorc\t$hetc\t$majorc\t$no\t$minor\t$het\t$major\t".
			($hets{$snp} ? 1 : 0)."\t".($homs{$snp} ? 1 : 0).
			"\n";
	}
	
	close OUT;
	
	close IN;
	
	#die "Arse\n";
}


else {

	# READ GENOTYPING DATA TO GET COUNTS
	####################################
	
		
		while(<>) {
			chomp;
			
			($snp, $samp, $geno, $num) = split /\t/, $_;
			
			$geno =~ s/\-/N/g;
			
			if(scalar keys %snplist) {
				next unless $snplist{$snp};
			}
			
			if(scalar keys %exclude) {
				next if $exclude{$samp};
			}
			
			$counts{$snp}{$geno}++;
			
			$totals{$snp}++ unless $geno =~ /n/i;
		}
	
	# IDENTIFY RARE HOMS/HETS AND OUTPUT GENOTYPE COUNTS
	####################################################
	
	debug("Identifying rare het SNPs");
	
	if(!$args{'ng'}) {
		open OUT, ">".($args{'o'} ? $args{'o'}.'_' : '')."genotype.dist";
		print OUT "SNP\tCount(m)\tCount(h)\tCount(M)\tCount(-)\tMinor\tHet\tMajor\trareHet\trareHom\n";
		
		debug("Writing genotype counts to ".($args{'o'} ? $args{'o'}.'_' : '')."genotype.dist");
	}
	
	foreach $snp(keys %counts) {
		# identify major / minor allele
		$max = 0;
		$major = '??';
		$minor = '??';
		$het = '??';
		$prev = '??';
		
		foreach $geno(keys %{$counts{$snp}}) {
			if(isHet($geno)) {
				$het = $geno;
			}
			
			elsif($geno !~ /n/i) {
				$minor = $geno;
			
				if($counts{$snp}{$geno} > $max) {
					$major = $geno;
					$minor = $prev;
					$max = $counts{$snp}{$geno};
					$prev = $geno;
				}
			}
		}
		
		$minor = '??' if $minor eq $major;
		
		
		#  identify rare hets and homs
		foreach $geno(keys %{$counts{$snp}}) {
		
			# identify rare hets
			if(isHet($geno) && (!$args{'nht'}) && ($counts{$snp}{$geno} / $totals{$snp} <= $het_frac) && ($counts{$snp}{$minor} == 0)) {
				$hets{$snp} = $counts{$snp}{$geno};
			
				$hetcont{$counts{$snp}{$geno}}{$snp} = 1;
			}
			
			# identify rare homs
			elsif(
				isHom($geno) && 
				($geno eq $minor) && 
				(!$args{'nhm'}) && 
				($counts{$snp}{$geno} >= $counts{$snp}{$het}) && 
				($counts{$snp}{$het} / $totals{$snp} <= $hom_frac)
			) {
				$homs{$snp} = $counts{$snp}{$geno};
				
				$minorhoms{$snp} = $geno;
				
				$homcont{$counts{$snp}{$geno}}{$snp} = 1;
			}
		}
	
		
		# write out genotype frequencies
		if(!$args{'ng'}) {
			print OUT 
				$snp."\t".
				$counts{$snp}{$minor}."\t".
				$counts{$snp}{$het}."\t".
				$counts{$snp}{$major}."\t".
				$counts{$snp}{'NN'}."\t".
				$minor."\t".$het."\t".$major."\t".
				($hets{$snp} ? 1 : 0)."\t".
				($homs{$snp} ? 1 : 0)."\n";
		}
	}
	
	close OUT;
}

# OUTPUT SNP DISTRIBUTION
#########################

if(!$args{'ns'}) {
	debug("Writing SNP distribution to ".($args{'o'} ? $args{'o'}.'_' : '')."snp.dist");
	
	open OUT, ">".($args{'o'} ? $args{'o'}.'_' : '')."snp.dist";
	
	unless($args{'nht'}) {
		print OUT "Rare heterozygotes:\n\nCount\tNum_SNPs\n";
	
		foreach $num(sort {$a <=> $b} keys %hetcont) {
			print OUT $num."\t".(scalar keys %{$hetcont{$num}})."\n";
		}
	}
	
	unless($args{'nhm'}) {
		print OUT "\n\n---------------------\n\nRare homozygotes:\n\nCount\tNum_SNPs\n";
	
		foreach $num(sort {$a <=> $b} keys %homcont) {
			print OUT $num."\t".(scalar keys %{$homcont{$num}})."\n";
		}
	}
	
	close OUT;
}

if($args{'nm'}) {
	debug("Done");
	die "Finished\n";
}

# CALCULATE SAMPLE DISTRIBUTION
###############################

debug("Calculating sample distribution");

foreach $file(@files) {
	
	open IN, $file;
	
	while(<IN>) {
		chomp;
		
		($snp, $samp, $geno, $num) = split /\t/, $_;
			
		if(scalar keys %snplist) {
			next unless $snplist{$snp};
		}
		
		if(scalar keys %exclude) {
			next if $exclude{$samp};
		}
		
		# count rare hets
		$hetcounts{$samp}{$snp} = 1 if (isHet($geno) && $hets{$snp} && (!$args{'nht'}));
		$hetcountsnum{$samp}++ if (isHet($geno) && $hets{$snp} && (!$args{'nht'}));
		
		# count rare homs
		$homcounts{$samp}{$snp} = 1 if (isHom($geno) && $homs{$snp} && (!$args{'nhm'}) && ($minorhoms{$snp} eq $geno));
	}
	
	close IN;
}

# ELIMINATE POTENTIALLY LINKED SNP BLOCKS
#########################################

if(keys %snps) {
	debug("Eliminating redundant SNPs in linked blocks");
	
	$prev_chrom = 0;
	
	# hets
	unless($args{'nht'}) {
		foreach $samp(keys %hetcounts) {
			foreach $snp(sort {$snps{$a}{'chr'} <=> $snps{$b}{'chr'} || $snps{$a}{'pos'} <=> $snps{$b}{'pos'}} keys %{$hetcounts{$samp}}) {
				$prev_pos = 0 - (2 * $dist_thresh) if $snps{$snp}{'chr'} ne $prev_chrom;
				
				delete $hetcounts{$samp}{$snp} if ($snps{$snp}{'pos'} - $prev_pos) < $dist_thresh;
				
				$prev_pos = $snps{$snp}{'pos'};
				$prev_chrom = $snps{$snp}{'chr'}
			}
			
			$prev_chrom = 0;
		}
	}
	

	
	$snplist = 1;	$prev_chrom = 0;
	
	# homs
	unless($args{'nhm'}) {
		foreach $samp(keys %homcounts) {
			foreach $snp(sort {$snps{$a}{'chr'} <=> $snps{$b}{'chr'} || $snps{$a}{'pos'} <=> $snps{$b}{'pos'}} keys %{$homcounts{$samp}}) {
				$prev_pos = 0 - (2 * $dist_thresh) if $snps{$snp}{'chr'} ne $prev_chrom;
				
				delete $homcounts{$samp}{$snp} if ($snps{$snp}{'pos'} - $prev_pos) < $dist_thresh;
				
				$prev_pos = $snps{$snp}{'pos'};
				$prev_chrom = $snps{$snp}{'chr'}
			}
			
			$prev_chrom = 0;
		}
	}
}


debug("Writing sample distribution to ".($args{'o'} ? $args{'o'}.'_' : '')."sample.dist");

open OUT, ">".($args{'o'} ? $args{'o'}.'_' : '')."sample.dist";
open OUTA, ">".($args{'o'} ? $args{'o'}.'_' : '')."full.sample.dist";

print OUT "Sample".($args{'nht'} ? "" : "\tNum_rare_hets").($args{'nhm'} ? "" : "\tNum_rare_homs")."\n";

# make a list of samples
%list = ();

foreach $samp(keys %hetcounts) { $list{$samp} = 1; }
foreach $samp(keys %homcounts) { $list{$samp} = 1; }


foreach $samp(sort {(scalar keys %{$hetcounts{$a}}) <=> (scalar keys %{$hetcounts{$b}})} keys %list) {
	$numhets = scalar keys %{$hetcounts{$samp}};
	$numhoms = scalar keys %{$homcounts{$samp}};

	print OUT 
		$samp.
		($args{'nht'} ? "" : "\t".($numhets ? $numhets : 0)).
		($args{'nhm'} ? "" : "\t".($numhoms ? $numhoms : 0)).
		"\n";
		
	if($args{'full'}) {
		foreach $snp(keys %{$hetcounts{$samp}}) {
			print OUTA "$samp\t$snp\tHET\n";
		}
		
		foreach $snp(keys %{$homcounts{$samp}}) {
			print OUTA "$samp\t$snp\tHOM\n";
		}
	}
}

close OUT;
close OUTA;



# SUBROUTINE TO IDENTIFY HETS
#############################

sub isHet {
	$geno = shift;
	
	$result = 0;
	
	$result = 1 if substr($geno,0,1) ne substr($geno,1,1);
	
	return $result;
}


# SUBROUTINE TO IDENTIFY HOMS
#############################

sub isHom {
	$geno = shift;
	
	$result = 0;
	
	return $result if $geno =~ /n/i;
	
	$result = 1 if substr($geno,0,1) eq substr($geno,1,1);
	
	return $result;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime();
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
} 


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
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}