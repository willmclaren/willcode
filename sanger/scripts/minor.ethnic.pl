#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;
use CGI qw/:standard/;
use CGI::Pretty;

$usage =<<END;
perl ethnic.freqs.pl
	-r	Reference panel ID
	-e	Other population ID
	-o	Output file stem
	-f	Frequency data file
	-t	Threshold for MAF in ethnic population
END

die $usage unless @ARGV;

# define some stuff
@pop_order = qw/CEU CHB JPT YRI CHB+JPT/;

# DEAL WITH ARGUMENTS
#####################

#debug("Processing arguments");

$args{'t'} = 0.1;

# define a list of arguments that have values to shift
%args_with_vals = (
	'f' => 1,
	'l' => 1,
	'r' => 1,
	'e' => 1,
	'o' => 1,
	'd' => 1,
	's' => 1,
	't' => 1,
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


# GET FREQUENCY DATA
####################

open IN, $args{'f'} or die ($args{'f'} ? "Could not open frequency file $args{'f'}\n" : "Frequency file not specified - use -f freq_file\n");

#debug("Loading frequency data from $args{'f'}");

SNP: while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	
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
		
		if($pop eq $args{'r'}) {
			$freqs{$snp}{'r'}{$allele_a} = $freq_a;
			$freqs{$snp}{'r'}{$allele_b} = $freq_b;
			
			#$mono{$snp} if (($freq_a == 0) || ($freq_b == 1));
		}
		
		elsif($pop eq $args{'e'}) {
			$freqs{$snp}{'e'}{$allele_a} = $freq_a;
			$freqs{$snp}{'e'}{$allele_b} = $freq_b;
		}
	}
}

close IN;


# debug("Loaded data for ".(scalar keys %freqs)." SNPs");
# debug((scalar keys %excluded)." SNPs rejected for strand ambiguity");
# debug("Loaded data for ".(scalar keys %mono)." $args{'r'}-monomorphic SNPs");



# GO THROUGH GENOTYPING DATA
############################

#debug("Parsing genotype data");

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $num) = split /\t/, $_;
	
    # check the SNP is monomorphic in CEU
	next unless $freqs{$snp};
	#next unless $mono{$snp};
	
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
		$allele = substr($geno,0,1);
		
		$freq = $freqs{$snp}{'e'}{$allele};
		
		next if $freq < $args{'t'};
		next if $freq > (1-$args{'t'});
		
		print "$snp\t2\n";
	}
	
	else {
		# flip reverse it if necessary
		unless($freqs{$snp}{'e'}{substr($geno,0,1)}) {
			$geno =~ tr/ACGT/TGCA/;
		}
		
		if($freqs{$snp}{'r'}{substr($geno,0,1)} == 0) {
			next if $freqs{$snp}{'e'}{substr($geno,0,1)} < $args{'t'};
			next if $freqs{$snp}{'e'}{substr($geno,0,1)} > (1-$args{'t'});
			
			print "$snp\t3\n";
		}
		
		else {
			print "$snp\t1\n";
		}
	}
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