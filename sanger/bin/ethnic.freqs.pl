#!/usr/bin/perl

$usage =<<END;
perl ethnic.freqs.pl
	-r	Reference panel ID
	-e	Other population ID
	-o	Output file stem
	-l	List of markers in panel
	-ln	List of markers to be excluded
	-f	Frequency data file
	-d	Distance to reduce SNP panel using
	-s	SNP information file for reducing distance
	-a	Output file with all samples / SNPs details
END

die $usage unless @ARGV;

# define some stuff
@pop_order = qw/CEU CHB JPT YRI CHB+JPT/;

# DEAL WITH ARGUMENTS
#####################

debug("Processing arguments");

# define a list of arguments that have values to shift
%args_with_vals = (
	'f' => 1,
	'l' => 1,
	'r' => 1,
	'e' => 1,
	'o' => 1,
	'd' => 1,
	's' => 1,
	'ln' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# process the arguments
$args{'r'} = "\U$args{'r'}";
$args{'e'} = "\U$args{'e'}";

die "Invalid reference population identifier \"$args{'r'}\" given\n" unless $args{'r'} =~ /CEU|CHB|JPT|YRI/;
die "Invalid ethnic group population identifier \"$args{'e'}\" given\n" unless $args{'e'} =~ /CEU|CHB|JPT|YRI/;


# GET SNP INFO
##############

if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	debug("Loading SNP info from $args{'s'}");
	
	$c = 0;
	
	while(<IN>) {
		chomp;
		
		($snp, $chrom, $pos) = split /\s+/, $_;
		$snp_info{$snp}{'chr'} = $chrom;
		$snp_info{$snp}{'pos'} = $pos;
		
		$c++;
	}
	
	close IN;
	
	debug("Loaded info for $c SNPs");
}


# GET SNP EXCLUSION LIST
########################

if($args{'ln'}) {
	open IN, $args{'ln'} or die "Could not open list of SNPs to exclude $args{'ln'}\n";
	
	debug("Loading SNP exclusion list from $args{'ln'}");
	
	while(<IN>) {
		chomp;
		
		$exclude{(split /\s+/, $_)[0]} = 1;
	}
	
	close IN;
	
	debug("Loaded an exclusion list containing ".(scalar keys %exclude)." SNPs");
}



# GET SNP LIST
##############

open IN, $args{'l'} or die ($args{'l'} ? "Could not open list file $args{'l'}\n" : "SNP list file not specified - use -l list_file\n");

debug("Loading SNP list from $args{'l'}");

$c = 0;

while(<IN>) {
	chomp;
	
	$snp = (split /\t/, $_)[0];
	
	$list{$snp} = 1 unless $exclude{$snp};
	$c++ if $exclude{$snp};
	
}

close IN;

debug("List contains ".(scalar keys %list)." SNPs ".($c ? "($c removed using exclude list)" : ""));

$genofile = shift @ARGV;


# GET FREQUENCY DATA
####################

open IN, $args{'f'} or die ($args{'f'} ? "Could not open frequency file $args{'f'}\n" : "Frequency file not specified - use -f freq_file\n");

debug("Loading frequency data from $args{'f'}");

SNP: while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	next unless $list{$snp};
	next if $exclude{$snp};
	
	foreach $pop(@pop_order) {
		$allele_a = shift @data;
		$freq_a = shift @data;
		$allele_b = shift @data;
		$freq_b = shift @data;
		
		if((join "", (sort ($allele_a, $allele_b))) =~ /AT|CG/i) {
			delete $list{$snp};
			$excluded{$snp} = 1;
			next SNP;
		}
		
		#print "$snp\t$pop\t$args{'r'}\t$args{'e'}\t$allele_a\t$freq_a\t$allele_b\t$freq_b\n";
		
		if($pop eq $args{'r'}) {
# 			unless($allele_a =~ /acgt/i) {
# 				delete $list{$snp};
# 				next;
# 			}
		
			$freqs{$snp}{'r'}{$allele_a} = $freq_a;
			$freqs{$snp}{'r'}{$allele_b} = $freq_b;
		}
		
		elsif($pop eq $args{'e'}) {
# 			unless($allele_a =~ /acgt/i) {
# 				delete $list{$snp};
# 				next;
# 			}
		
			$freqs{$snp}{'e'}{$allele_a} = $freq_a;
			$freqs{$snp}{'e'}{$allele_b} = $freq_b;
		}
	}
}

close IN;


debug("Loaded data for ".(scalar keys %freqs)." SNPs");
debug((scalar keys %excluded)." SNPs rejected for strand ambiguity");






# ELIMINATE SNPS
################

if($args{'d'} && $args{'s'}) {
	debug("Scanning genotype file to get final SNP list");

	# we need to scan the genotypes file first
	open GENO, $genofile;
	
	while(<GENO>) {
		chomp;
		
		($snp, $samp, $geno, $crap) = split /\s+/, $_;
		
		next if $exclude{$snp};
		next unless $list{$snp};
		
		$in_file{$snp} = 1;
	}
	
	close GENO;

	foreach $snp(sort {$snp_info{$a}{'chr'} <=> $snp_info{$b}{'chr'} || $snp_info{$a}{'pos'} <=> $snp_info{$b}{'pos'}} keys %list) {
		delete $list{$snp} unless $in_file{$snp};
	
		if(($snp_info{$snp}{'chr'} == $prev_chrom) && (($snp_info{$snp}{'pos'} - $prev_pos) < $args{'d'})) {
			delete $list{$snp};
		}
		
		else {
			$prev_pos = $snp_info{$snp}{'pos'};
			$prev_chrom = $snp_info{$snp}{'chr'};
		}
	}
	
	debug("List pruned to ".(scalar keys %list)." SNPs");
}



# GO THROUGH GENOTYPING DATA
############################

debug("Parsing genotype data");

open GENO, $genofile;

while(<GENO>) {
	chomp;
	
	($snp, $sample, $geno, $num) = split /\t/, $_;
	
    # check the SNP is in the list
	next unless $list{$snp};
	next if $exclude{$snp};
	
    # skip if missing genotype
	next if $geno =~ /n/i;

	# check that the alleles in this genotype appear in the freqs hash
	$found = 0;
	
    foreach $allele(split //, $geno) {
		$found = 1 if $freqs{$snp}{'e'}{$allele};
	}
	
	if(!$found) {
		$cheese = 1;
	}
	
	
	if(isHet($geno)) {
		$counts{$sample}{'het'}++;
		$totals{$sample}++;
		
		$full{$sample}{$snp} = 'HET' if $args{'a'};
		
		$dist{$snp}{'het'}++;
	}
	
	else {
		#print "$sample\t$snp\t$geno\t$args{'r'}\t".$freqs{$snp}{'r'}{substr($geno,0,1)}."\t$args{'e'}\t".$freqs{$snp}{'e'}{substr($geno,0,1)}."\n";
		
		# flip reverse it if necessary
		unless($freqs{$snp}{'e'}{substr($geno,0,1)}) {
			$geno =~ tr/ACGT/TGCA/;
		}
		
		if($freqs{$snp}{'r'}{substr($geno,0,1)} == 0) {
			$counts{$sample}{'e'}++;
			$totals{$sample}++;
			$dist{$snp}{'e'}++;
			$full{$sample}{$snp} = 'HOM' if $args{'a'};
		}
		
		else {
			$counts{$sample}{'r'}++;
			$totals{$sample}++;
			$dist{$snp}{'r'}++;
			$full{$sample}{$snp} = 'REFHOM' if $args{'a'};
		}
	}
}

unless($args{'nf'}) {
	$outfile = $args{'o'}."_freq.dist";
	
	debug("Calculating frequencies");
	
	foreach $sample(keys %counts) {
		$out{$sample}{'e'} = $counts{$sample}{'e'}/$totals{$sample};
		$out{$sample}{'het'} = $counts{$sample}{'het'}/$totals{$sample};
		$out{$sample}{'r'} = $counts{$sample}{'r'}/$totals{$sample};
	}
	
	debug("Writing frequencies to $outfile\n");
	
	open OUT, ">$outfile";
	
	foreach $sample(sort {$out{$a}{'r'} <=> $out{$b}{'r'}} keys %out) {
		print OUT "$sample\t";
		print OUT (join "\t", (
			$out{$sample}{'e'},
			$out{$sample}{'het'},
			$out{$sample}{'r'}
		));
		print OUT "\t$totals{$sample}\n";
	}
	
	close OUT;
}

if($args{'a'}) {
	$outfile = $args{'o'}."_full.dist";
	
	debug("Writing full details to $outfile");
	
	open OUT, ">$outfile";
	
	foreach $sample(keys %full) {
		foreach $snp(keys %{$full{$sample}}) {
			print OUT "$sample\t$snp\t$full{$sample}{$snp}\n";
		}
	}
	
	close OUT;
}

unless($args{'ns'}) {
	$outfile = $args{'o'}."_snpcount.dist";
	
	debug("Writing SNP distribution to $outfile\n");
	
	open OUT, ">$outfile";
	
	foreach $snp(keys %dist) {
		$hetsnpcount{$dist{$snp}{'het'}}++;
		$homsnpcount{$dist{$snp}{'e'}}++;
	}
	
	print OUT "Het counts:\n\n";
	
	foreach $count(sort {$a <=> $b} keys %hetsnpcount) {
		next unless $count >= 1;
		print OUT "$count\t$hetsnpcount{$count}\n";
	}
	
	print OUT "\n\nHom counts:\n\n";
	
	foreach $count(sort {$a <=> $b} keys %homsnpcount) {
		next unless $count >= 1;
		print OUT "$count\t$homsnpcount{$count}\n";
	}
	
	close OUT;
}


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