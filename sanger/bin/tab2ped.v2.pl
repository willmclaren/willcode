#!/usr/bin/perl

# set defaults for argument values
$args{'o'} = "default";
#$args{'a'} = "0";

# set a list of command line flags that we expect to have a value following them
%args_with_vals = (
	's' => 1,
	'm' => 1,
	'o' => 1,
#	'a' => 1,
);

# process arguments in to %args hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# if a marker information file has been supplied
if(-e $args{'m'}) {
	open IN, $args{'m'} or die "Could not read from file $arg{'m'}\n";
	
	while(<IN>) {
		chomp;
		($snp, $chr, $pos) = split /\s+/, $_;
		
		# record the chromosome and position of each SNP for use in map file
		$chr{$snp} = $chr;
		$pos{$snp} = $pos;
	}
	
	close IN;
}

# print "rs868950\t".$chr{'rs868950'}."\t".$pos{'rs868950'}."\n";

# die;

# if a sample information file has been supplied
if(-e $args{'s'}) {
	open IN, $args{'s'} or die "Could not read from file $arg{'s'}\n";
	
	while(<IN>) {
		chomp;
		
		#($sample, $gender, $condition, $set, $plate, $region) = split /\s+/, $_;
		
		($family, $sample, $dad, $mum, $gender, $aff) = split /\s+/, $_;
		
		if($gender =~ /fema/i) {
			$gender = 2;
		}
		elsif($gender =~/male/i) {
			$gender = 1;
		}
		
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

while(<>) {
	next if /^\#/;

	chomp;
	@data = split /\s+/, $_;
	
	# header line contains order of SNPs
	if(/^\s/) {
		# the first column could be blank
		shift @data unless $data[0] =~ /rs/;
		
		# open the map file for writing
		open MAP, ">".$args{'o'}.".map" or die "Could not write to map file ".$args{'o'}.".map";
		
		foreach $snp(@data) {
			print MAP
				($chr{$snp} ? $chr{$snp} : "?")."\t".
				"$snp\t".
				"0\t".
				($pos{$snp} ? $pos{$snp} : "?")."\n";
		}
		
		close MAP;
	}
	
	# otherwise assume this is a line of data
	else {
		# get the sample ID
		$sample = shift @data;
		
		print OUT 
			($sample_info{$sample}{'family'} ? $sample_info{$sample}{'family'} : $sample)."\t".	# family ID
			($sample_info{$sample}{'family'} ? $sample : 1)."\t".								# sample ID
			($sample_info{$sample}{'dad'} ? $sample_info{$sample}{'dad'} : 0)."\t".				# dad ID
			($sample_info{$sample}{'mum'} ? $sample_info{$sample}{'mum'} : 0)."\t".				# mum ID
			($sample_info{$sample}{'gender'} ? $sample_info{$sample}{'gender'} : 0)."\t".		# gender (if known)
			($sample_info{$sample}{'aff'} ? $sample_info{$sample}{'aff'} : 0);					# affection status (if specified)
		
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
}

close OUT;