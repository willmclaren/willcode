#!/usr/bin/perl

use strict;
use Tie::File;

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
my %args_with_vals = (
	'cases' => 1,
	'controls' => 1,
	'markers' => 1,
	'list' => 1,
	'output' => 1,
	'a' => 1,
	'u' => 1,
	'm' => 1,
	'l' => 1,
	'o' => 1,
	'e' => 1,
	's' => 1,
	'p' => 1,
);

# define a usage message
my $usage =<<END;
Usage: perl prep.unphase.pl [options]

-----------------------------------------------------------

List of options requiring an argument:
	
	-a	Datafile for cases / affected samples
	-u	Datafile for controls / unaffected samples
	-m	File containing marker information
		(i.e. chromosome, position etc.)
	-s	File containing sample information
		(i.e. gender, region etc.)
	-l	File containing a list of markers to use.
		If not given, takes ages to read from datafiles
	-e	File containing a list of samples to exclude
	-o	Stem for output files e.g. -o output/ will make
		output/chr1.ped output/chr2.ped etc.
	-p	Pedigree information file

-----------------------------------------------------------
			
List of options without an argument (i.e. flags)
	
	-np	If specified, .ped files won't be created
	-nm	If specified, .map files won't be created
	-nc	If specified, "clusters.txt" won't be created
	-c	If specified, assumes data is NOT ordered by sample (NEEDS LOTS OF MEMORY!!!)
	-outlier	Formats output for outlier program
END

# if no arguments have been given, give a usage message
if($ARGV[0] !~ /^\-/) {
	die $usage;
}

# create a hash to keep arguments in
our %args;

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	my $val;
	
	if($args_with_vals{$arg}) {
		my @vals = ();
	
		# add all values found
		while(@ARGV && ($ARGV[0] !~ /^\-/)) {
			push @vals, shift @ARGV;
		}
		
		# join the array into a string
		$val = join ',', @vals;
	}
	
	# give args that don't take a value a nominal value of 1
	else {
		$val = 1;
	}
	
	$args{$arg} = $val;
}

# check that we have been given either a case or control datafile
# unless($args{'a'} || $args{'u'} || $args{'cases'} || $args{'controls'}) {
# 	die "No data file\(s\) supplied\n\n".$usage;
# }



# GET LIST OF MARKERS
#####################

debug("Getting list of markers");

my $markers_in_use;

# if we have been supplied with a list of markers, load them in
if($args{'l'} || $args{'list'}) {
	my $marker_file = ($args{'l'} ? $args{'l'} : $args{'list'});

	open IN, $marker_file or die "Could not open marker file ".$marker_file."\n";
	
	while(<IN>) {
		chomp;
		$markers_in_use->{(split /\t/, $_)[0]} = 1;
	}
	
	close IN;
}

# otherwise we have to scan the data files to get a unique maximal set
elsif($args{'a'} || $args{'cases'} || $args{'u'} || $args{'controls'}) {

	# make a list of data files to scan
	my @files;
	
	if($args{'a'} || $args{'cases'}) {
		push @files, (split /\,/, $args{'a'});
	}
	
	if($args{'u'} || $args{'controls'}) {
		push @files, (split /\,/, $args{'u'});
	}
	
	# scan the files
	foreach my $file(@files) {
		debug("Reading data file ".$file);
	
		open IN, $file or die "Could not open data file ".$file."\n";
		
		while(<IN>) {
			$markers_in_use->{(split /\s+/, $_)[0]} = 1;
		}
		
		close IN;
	}
}

debug("Found ".(scalar keys %$markers_in_use)." unique markers");



# LOAD SNP REFERENCE DATA IF GIVEN
##################################

our $snps;
our %chrom;


if($args{'m'} || $args{'markers'}) {

	my $file = ($args{'m'} ? $args{'m'} : $args{'markers'});
	
	debug("Reading SNP reference data from ".$file);
	
	open IN, $file or die "Could not open markers file ".$file."\n";
	
	my @data;
	
	while(<IN>) {
	
		# skip this line unless it has numerical data on it
		next unless /\d/;
		
		chomp;
		
		@data = split /\s+/, $_;
		
		# check that we need the data for this SNP
		next unless $markers_in_use->{$data[0]};
		
		# try and guess the format of the file to parse it
		if(scalar @data == 4) {
			#       chrom       SNP         pos
			$snps->{$data[2]}->{$data[0]} = $data[3];
			
			$chrom{$data[0]} = $data[2];
		}
		
		elsif(/Infinium/) {
			#       chrom       SNP         pos
			$snps->{$data[3]}->{$data[0]} = $data[4];
			
			$chrom{$data[0]} = $data[3];
		}
		
		else {
			#       chrom       SNP         pos
			$snps->{$data[1]}->{$data[0]} = $data[2];
			
			$chrom{$data[0]} = $data[1];
		}
	}
}


# LOAD AN EXCLUDE LIST
######################
	
our %exclude;

if($args{'e'}) {
	debug("Reading excluded sample list ".$args{'e'});

	open IN, $args{'e'} or die "Could not open exclude file ".$args{'e'};
	while(<IN>) { chomp; $exclude{$_} = 1; }
	close IN;
}


# LOAD SAMPLE INFO FILE
#######################

our %sample_info;

if($args{'s'}) {
	foreach my $file(split /\,/, $args{'s'}) {
		debug("Reading sample information file ".$file);
	
		open IN, $file or die "Could not open sample information file ".$file;
		
		while(<IN>) {
			next if /^\#/;
		
			chomp;
			
			my ($sample, $gender, $condition, $set, $plate, $region) = split /\s+/, $_;
			
			$sample_info{$sample}{'region'} = $region;
			$sample_info{$sample}{'gender'} = $gender;
			#$sample_info{$sample}{'age'} = $age;
		}
		
		close IN;
	}
}


# LOAD PEDIGREE INFO FILE
#########################

our %ped_info;

if($args{'p'}) {
	open IN, $args{'p'} or die "Could not open pedigree file ".$args{'p'};
	
	while(<IN>) {
		chomp;
		
		my @data = split /\s+|\,/, $_;
		
		if(scalar @data == 4) {
			$ped_info{$data[0]}{'pedid'} = $data[1];
			$ped_info{$data[0]}{'dadid'} = $data[2];
			$ped_info{$data[0]}{'momid'} = $data[3];
		}
		
		else {
			$ped_info{$data[4]}{'pedid'} = $data[3];
			$ped_info{$data[4]}{'dadid'} = $data[5];
			$ped_info{$data[4]}{'momid'} = $data[6];
			
			unless(scalar keys %sample_info) {
				$sample_info{$data[4]}{'gender'} = $data[7];
			}
		}
	}
	
	close IN;
}


# NOW PROCESS THE GENOTYPING DATA
#################################

unless($args{'np'}) {

	if($args{'u'} || $args{'controls'}) {
		debug("Writing .ped files for controls");
	
 		if($args{'c'}) {
			writePedComplete($args{'u'}, 1);
		}
		
		else {
			writePed($args{'u'}, 1);
		}
	}
	
	if($args{'a'} || $args{'cases'}) {
		debug("Writing .ped files for cases");
	
		if($args{'c'}) {
			writePedComplete($args{'a'}, 2);
		}
		
		else {
			writePed(($args{'a'} ? $args{'a'} : $args{'cases'}), 2);
		}
	}
}


# MAKE MAP FILES
################

unless($args{'nm'}) {

	debug("Making map files");
	
	foreach my $chrom(sort {$a <=> $b} keys %{$snps}) {
		my $outfile;
	
		if($args{'outlier'}) {
			$outfile = ($args{'o'} ? $args{'o'} : "").".info";
		}
		
		else {
			$outfile = ($args{'o'} || $args{'output'} ? ($args{'o'} ? $args{'o'} : $args{'output'}) : "")."chr".$chrom.".map";
		}
		
		open OUT, ">".$outfile or die "Could not write to map file ".$outfile;
		
		#debug("Writing to map file ".$outfile);
	
		foreach my $snp(sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}}) {	
			if($args{'outlier'}) {
				print OUT "$snp\t$chrom\t$snps->{$chrom}->{$snp}\n";
			}
			else {
				print OUT "$chrom\t$snp\t0\t$snps->{$chrom}->{$snp}\n";
			}
		}
		
		close OUT;
	}
}


# MAKE CLUSTER FILE
####################

unless($args{'nc'} || (!$args{'s'})) {
	
	my $outfile = ($args{'o'} || $args{'output'} ? ($args{'o'} ? $args{'o'} : $args{'output'}) : "")."clusters.txt";
	
	debug("Making cluster file ".$outfile);
	
	open OUT, ">".$outfile or die "Could not write to cluster file ".$outfile;
	
	foreach my $sample(keys %sample_info) {
		my $region = $sample_info{$sample}{'region'};
		$region =~ s/\s+/\_/g;
	
		print OUT $sample."\t1\t".($region ? $region : "Unknown")."\n";
	}
	
	close OUT;
}



# MAKE PED FILES FROM MULTIPLE INPUT FILES
##########################################

sub writePed {
	my @files = split /\,/, shift;
	my $phen = (@_ ? shift : 1);
	
	foreach my $file(@files) {
		open IN, $file or die "Could not open data file ".$file;
		
		my @data = ();
		my $sample = '';
		my %geno = ();
		my %seen_chroms = ();
		
		while(<IN>) {
			chomp;
			
			@data = split /\s+/, $_;
			
			next if $exclude{$data[1]};
			
			# translate bases to numbers
			$data[2] =~ tr/\-NACGT/001234/;
			
			if(($data[1] ne $sample) && (scalar keys %geno >= 1)) {
			
				#debug("Writing data for sample ".$sample);
				
				# write out the data
				foreach my $chrom(sort {$a <=> $b} keys %seen_chroms) {
					next if $chrom =~ /chrom/i;
					
					my $outfile;
					
					if($args{'outlier'}) {
						$outfile = ($args{'o'} ? $args{'o'} : "").".data";
					}
					
					else {
						$outfile = ($args{'o'} || $args{'output'} ? ($args{'o'} ? $args{'o'} : $args{'output'}) : "")."chr".$chrom.".ped";
					}
					
					#debug("Writing to ".$outfile);
					
					open OUT, ">>".$outfile or die "Could not open output file ".$outfile."\n";
						
					if($args{'outlier'}) {
						print OUT $sample;
					}
					
					else {
						print OUT (join "\t",
							(
								($ped_info{$sample} ? $ped_info{$sample}{'pedid'} : $sample),	# sample ID
								($ped_info{$sample} ? $sample : 1),								# subject ID
								($ped_info{$sample} ? $ped_info{$sample}{'dadid'} : 0),			# father ID
								($ped_info{$sample} ? $ped_info{$sample}{'momid'} : 0),			# mother ID
								($sample_info{$sample}{'gender'} =~ /1|2/ ? $sample_info{$sample}{'gender'} : '0'), # gender
								$phen		# phenotype
							)
						);
					}
				
					foreach my $snp(sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}}) {
						
						# alter the data for this point if the sample is male and this is the X chromosome
						$geno{$snp} = substr($geno{$snp}, 0, 1).'0' if (($sample_info{$sample}{'gender'} == 1) && ($chrom =~ /x/i));
					
						if($args{'outlier'}) {
							$geno{$snp} =~ tr/01234/NACGT/ if $geno{$snp};
							print OUT "\t".($geno{$snp} ? $geno{$snp} : "NN");
						}
						
						else {
							print OUT "\t".($geno{$snp} ? (join " ", split "", $geno{$snp}) : "0 0");
						}
					}
					
					print OUT "\n";
					
					close OUT;
				}
				
				%seen_chroms = ();
				%geno = ();
			}
			
			$geno{$data[0]} = $data[2];
			$sample = $data[1];
			$seen_chroms{$chrom{$data[0]}} = 1;
		}
	
		close IN;
		
		# write out the rest of the data
		foreach my $chrom(sort {$a <=> $b} keys %seen_chroms) {
			next if $chrom =~ /chrom/i;
			my $outfile;
			
			if($args{'outlier'}) {
				$outfile = ($args{'o'} ? $args{'o'} : "").".data";
			}
			
			else {
				$outfile = ($args{'o'} || $args{'output'} ? ($args{'o'} ? $args{'o'} : $args{'output'}) : "")."chr".$chrom.".ped";
			}
			
			open OUT, ">>".$outfile or die "Could not open output file ".$outfile."\n";
						
			if($args{'outlier'}) {
				print OUT $sample;
			}
			
			else {
				print OUT (join "\t",
					(
						($ped_info{$sample} ? $ped_info{$sample}{'pedid'} : $sample),	# sample ID
						($ped_info{$sample} ? $sample : 1),								# subject ID
						($ped_info{$sample} ? $ped_info{$sample}{'dadid'} : 0),			# father ID
						($ped_info{$sample} ? $ped_info{$sample}{'momid'} : 0),			# mother ID
						($sample_info{$sample}{'gender'} =~ /1|2/ ? $sample_info{$sample}{'gender'} : '0'), # gender
						$phen		# phenotype
					)
				);
			}
		
			foreach my $snp(sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}}) {
				
				# alter the data for this point if the sample is male and this is the X chromosome
				$geno{$snp} = substr($geno{$snp}, 0, 1).'0' if (($sample_info{$sample}{'gender'} == 1) && ($chrom =~ /x/i));
			
				if($args{'outlier'}) {
					$geno{$snp} =~ tr/01234/NACGT/ if $geno{$snp};
					print OUT "\t".($geno{$snp} ? $geno{$snp} : "NN");
				}
				
				else {
					print OUT "\t".($geno{$snp} ? (join " ", split "", $geno{$snp}) : "0 0");
				}
			}
			
			print OUT "\n";
			
			close OUT;
		}
	}
}



# MAKE PED FILES FROM MULTIPLE UNORDERED INPUT FILES
####################################################

sub writePedComplete {
	my @files = split /\,/, shift;
	my $phen = (@_ ? shift : 1);
	
	my $sample;
	my %geno = ();
	my %seen_chroms = ();
	
	foreach my $file(@files) {
		open IN, $file or die "Could not open data file ".$file;
		
		my @data = ();
		
		while(<IN>) {
			chomp;
			
			@data = split /\s+/, $_;
			
			next if $exclude{$data[1]};
			
			# translate bases to numbers
			$data[2] =~ tr/\-NACGT/001234/;
			
			$geno{$data[1]}{$data[0]} = $data[2];
			$seen_chroms{$chrom{$data[0]}} = 1;
		}
	
		close IN;
	}
	
	# write out the data
	foreach my $chrom(sort {$a <=> $b} keys %seen_chroms) {
		next if $chrom =~ /chrom/i;
		my $outfile;
		
		if($args{'outlier'}) {
			$outfile = ($args{'o'} ? $args{'o'} : "").".data";
		}
		
		else {
			$outfile = ($args{'o'} || $args{'output'} ? ($args{'o'} ? $args{'o'} : $args{'output'}) : "")."chr".$chrom.".ped";
		}
		
		debug("Writing to ".$outfile);
		
		open OUT, ">>".$outfile or die "Could not open output file ".$outfile."\n";
			
		foreach $sample(keys %geno) {
			if($args{'outlier'}) {
				print OUT $sample;
			}
			
			else {
				print OUT (join "\t",
					(
						($ped_info{$sample} ? $ped_info{$sample}{'pedid'} : $sample),	# sample ID
						($ped_info{$sample} ? $sample : 1),								# subject ID
						($ped_info{$sample} ? $ped_info{$sample}{'dadid'} : 0),			# father ID
						($ped_info{$sample} ? $ped_info{$sample}{'momid'} : 0),			# mother ID
						($sample_info{$sample}{'gender'} =~ /1|2/ ? $sample_info{$sample}{'gender'} : '0'), # gender
						$phen		# phenotype
					)
				);
			}
		
			foreach my $snp(sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}}) {
				
				# alter the data for this point if the sample is male and this is the X chromosome
				$geno{$sample}{$snp} = substr($geno{$snp}, 0, 1).'0' if (($sample_info{$sample}{'gender'} == 1) && ($chrom =~ /x/i));
			
				if($args{'outlier'}) {
					$geno{$sample}{$snp} =~ tr/01234/NACGT/ if $geno{$sample}{$snp};
					print OUT "\t".($geno{$sample}{$snp} ? $geno{$sample}{$snp} : "NN");
				}
				
				else {
					print OUT "\t".($geno{$sample}{$snp} ? (join " ", split "", $geno{$sample}{$snp}) : "0 0");
				}
			}
			
			print OUT "\n";
		}
		
		close OUT;
	}
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
