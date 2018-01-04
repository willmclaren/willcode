#!/usr/bin/perl

# set defaults for argument values
$args{'o'} = "default";
$args{'a'} = "0";

# set a list of command line flags that we expect to have a value following them
%args_with_vals = (
	's' => 1,
	'm' => 1,
	'o' => 1,
	'a' => 1,
);

# process arguments in to %args hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# if a marker information file has been supplied
if(-e $args{'m'}) {
	open IN, $args{'m'};
	
	while(<IN>) {
		chomp;
		($snp, $chr, $pos) = split /\s+/, $_;
		
		# record the chromosome and position of each SNP for use in map file
		$chr{$snp} = $chr;
		$pos{$snp} = $pos;
	}
	
	close IN;
}


# if a sample information file has been supplied
if(-e $args{'s'}) {
	open IN, $args{'s'};
	
	while(<IN>) {
		chomp;
		($sample, $gender, $condition, $set, $plate, $region) = split /\s+/, $_;
		
		if($gender =~ /fema/i) {
			$gender = 2;
		}
		elsif($gender =~/male/i) {
			$gender = 1;
		}
		
		$family{$sample} = $plate;
		
		# record the gender of each sample for use in the ped file
		$gender{$sample} = $gender;
	}
	
	close IN;
}

# open the ped file for writing
open OUT, ">".$args{'o'}.".ped";

while(<>) {
	chomp;
	@data = split /\s+/, $_;
	
	# header line contains order of SNPs
	if(/^\s/) {
		# the first column could be blank
		shift @data unless $data[0] =~ /rs/;
		
		# open the map file for writing
		open MAP, ">".$args{'o'}.".map";
		
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
			($family{$sample} ? $family{$sample} : $sample)."\t".	# family ID
			($family{$sample} ? $sample : 1)."\t".					# sample ID
			"0\t0\t".												# family info (not used)
			($gender{$sample} ? $gender{$sample} : "0").			# gender (if known)
			"\t".$args{'a'};										# affection status (if specified)
		
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