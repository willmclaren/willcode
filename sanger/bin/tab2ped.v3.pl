#!/usr/bin/perl

use strict;

# ARGUMENTS
###########

my (%args, %args_with_vals);

# set defaults for argument values
$args{'o'} = "tab2ped";

# set a list of command line flags that we expect to have a value following them
%args_with_vals = (
	's' => 1,
	'm' => 1,
	'o' => 1,
);

# process arguments in to %args hash
while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# help
my $usage =<<END;

tab2ped.pl v0.3 by Will McLaren (wm2\@sanger.ac.uk)

Usage:

> perl tab2ped.pl [options] tabfile

Options:
 -h 			: Display this message
 -s sample_info_file	: Specify sample information file
 -m snp_infofile	: Specify SNP information/map file
 -o outfile_stem	: Specify a stem for output files [default "tab2ped"]
 
END

if(scalar @ARGV == 0 || $args{'h'} || $args{'help'} || $args{'-help'}) {
	print $usage;
	exit;
}


# if a marker information file has been supplied
my (%chr, %pos);
my ($chr, $snp, $crap, $pos);
my $line_num = 1;

if(-e $args{'m'}) {

	open IN, $args{'m'} or die "Could not read from file ".$args{'m'}."\n";
	
	while(<IN>) {
		chomp;
		my @data = split /\s+/, $_;
		
		# determine the file format by checking the number of columns
		# plain info file - SNP, Chrom, Pos
		if(scalar @data == 3) {
			($snp, $chr, $pos) = @data;
		}
		
		# standard map file - Chrom, SNP, Genetic distance, Pos
		elsif(scalar @data == 4) {
			($chr, $snp, $crap, $pos) = @data;
		}
		
		# otherwise we don't know how to deal with it
		else {
			die
				"Could not detect format of marker information file ".$args{'m'}.
				" - expected 3 or 4 columns but found ".(scalar @data)." on line ".$line_num."\n";
		}
		
		# sanity check that position is a number
		warn
			"Error in marker information file ".$args{'m'}." on line ".$line_num.
			" - position specified ".$pos." is not a number\n" unless $pos =~ /^\d+$/;
		
		
		# record the chromosome and position of each SNP for use in map file
		$chr{$snp} = $chr;
		$pos{$snp} = $pos;
		$line_num++;
	}
	
	close IN;
}


# if a sample information file has been supplied
my ($family, $sample, $dad, $mum, $gender, $aff);
my %sample_info;

if(-e $args{'s'}) {
	open IN, $args{'s'} or die "Could not read from file ".$args{'s'}."\n";
	
	# reset line counter
	$line_num = 1;
	
	while(<IN>) {
		chomp;
		
		my @data = split /\s+/, $_;
		
		# check number of columns of data
		die
			"Incorrect format for sample information file - ".
			"expected 6 columns of data but found ".(scalar @data).
			" on line ".$line_num."\n" unless scalar @data == 6;
		
		($family, $sample, $dad, $mum, $gender, $aff) = @data;
		
		# convert to gender conventions
		if($gender =~ /fema/i) {
			$gender = 2;
		}
		elsif($gender =~/male/i) {
			$gender = 1;
		}
		
		# store the information in a hash
		$sample_info{$sample}{'family'} = $family;
		$sample_info{$sample}{'dad'} = $dad;
		$sample_info{$sample}{'mum'} = $mum;
		$sample_info{$sample}{'gender'} = $gender;
		$sample_info{$sample}{'aff'} = $aff;
	}
	
	close IN;
}

# open the ped file for writing
open OUT, ">".$args{'o'}.".ped" or die "Could not write to ped file ".$args{'o'}.".ped";

# reset line counter
$line_num = 1;

while(<>) {

	# skip comment lines
	next if /^\#/;

	chomp;
	
	# clean off any leading whitespace
	#$_ =~ s/^\s+//g;
	
	# split data into array
	my @data = split /\s+/, $_;
	
	# header line contains order of SNPs
	if(/^\s/ && $line_num == 1) {
	
		# the first column could be blank
		shift @data unless $data[0] =~ /rs/;
		
		# open the map file for writing
		open MAP, ">".$args{'o'}.".map" or die "Could not write to map file ".$args{'o'}.".map";
		
		# iterate through the SNPs and write the map file
		foreach my $snp(@data) {
			print MAP
				(defined $chr{$snp} ? $chr{$snp} : "?")."\t".
				$snp."\t".
				"0\t".
				(defined $pos{$snp} ? $pos{$snp} : "?")."\n";
		}
		
		close MAP;
	}
	
	# otherwise assume this is a line of data
	else {
		# get the sample ID
		$sample = shift @data;
		
		print OUT 
			(defined $sample_info{$sample}{'family'} ? $sample_info{$sample}{'family'} : $sample)."\t".	# family ID
			(defined $sample_info{$sample}{'family'} ? $sample : 1)."\t".								# sample ID
			(defined $sample_info{$sample}{'dad'} ? $sample_info{$sample}{'dad'} : 0)."\t".				# dad ID
			(defined $sample_info{$sample}{'mum'} ? $sample_info{$sample}{'mum'} : 0)."\t".				# mum ID
			(defined $sample_info{$sample}{'gender'} ? $sample_info{$sample}{'gender'} : 0)."\t".		# gender (if known)
			(defined $sample_info{$sample}{'aff'} ? $sample_info{$sample}{'aff'} : 0);					# affection status (if specified)
		
		# go through each column with genotype data
		while(@data) {
			$a = shift @data;
			
			# convert '-' to '0' for PLINK
			$a =~ s/\-/0/g;
			
			# print out only the first bit of data (i.e. the genotype)
			print OUT "\t".(join " ", (split //, (split /\;/, $a)[0]));
		}
		
		# finish the line
		print OUT "\n";
	}
	
	$line_num++;
}

close OUT;