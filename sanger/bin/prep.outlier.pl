#!/usr/bin/perl

use strict;

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
my %args_with_vals = (
	'l' => 1,
	'o' => 1,
	'e' => 1,
	's' => 1,
	'qcg' => 1,
	'qcl' => 1,
);

# define a usage message
my $usage =<<END;
Usage: perl prep.outlier.pl [options] datafile

-----------------------------------------------------------

List of options requiring an argument:

	-s	File containing marker information
		(i.e. chromosome, position etc.)
	-l	File containing a list of markers to use.
		If not given, takes ages to read from datafiles
	-e	File containing a list of samples to exclude
	-o	Stem for output files e.g. -o output/ will make
		output/chr1.ped output/chr2.ped etc.

END

# if no arguments have been given, give a usage message
if($ARGV[0] !~ /^\-/) {
	die $usage;
}

# create a hash to keep arguments in
our %args;

# get the arguments into the hash
while($ARGV[0] =~ /^\-.+/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
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
my $marker_file = ($args{'l'} ? $args{'l'} : $args{'s'});

open IN, $marker_file or die "Could not open marker file ".$marker_file."\n";

while(<IN>) {
	chomp;
	$markers_in_use->{(split /\t/, $_)[0]} = 1;
}

close IN;

debug("Found ".(scalar keys %$markers_in_use)." unique markers");



# LOAD SNP REFERENCE DATA IF GIVEN
##################################

our $snps;
our %chrom;


if($args{'s'} || $args{'markers'}) {

	my $file = ($args{'s'} ? $args{'s'} : $args{'markers'});
	
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


debug("Loaded info for ".(scalar keys %chrom)." SNPs");


# LOAD AN EXCLUDE LIST
######################
	
our %exclude;

if($args{'e'}) {
	debug("Reading excluded sample list ".$args{'e'});

	open IN, $args{'e'} or die "Could not open exclude file ".$args{'e'};
	while(<IN>) { chomp; $exclude{$_} = 1; }
	close IN;
}

debug("Writing data file\n");
writePed(@ARGV);




# MAKE MAP FILES
################

unless($args{'nm'}) {

	debug("Making map files");
	
	my $outfile = ($args{'o'} ? $args{'o'} : "").($args{'p'} ? ".map" : ".info");
		
	open OUT, ">".$outfile or die "Could not write to map file ".$outfile;
	
	foreach my $chrom(sort {$a <=> $b} keys %$snps) {
		foreach my $snp(sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}}) {	
			print OUT ($args{'p'} ? "$chrom\t$snp\t0\t$snps->{$chrom}->{$snp}\n" : "$snp\t$chrom\t$snps->{$chrom}->{$snp}\n");
		}
	}
	
	close OUT;
}



# MAKE PED FILES FROM MULTIPLE INPUT FILES
##########################################

sub writePed {
	my @files = @_;
	my %order;
	my $geno;
	
	# make chrom orders
	foreach my $chrom(keys %$snps) {
		@{$order{$chrom}} = sort {$snps->{$chrom}->{$a} <=> $snps->{$chrom}->{$b}} keys %{$snps->{$chrom}};
	}
	
	my $outfile = ($args{'o'} ? $args{'o'} : "outlier").($args{'p'} ? ".ped" : ".data");
	open OUT, ">".$outfile or die "Could not open output file ".$outfile."\n";
	
	foreach my $file(@files) {
		open IN, $file or die "Could not open data file ".$file;
		
		my @data = ();
		my $sample = '';
		my %geno = ();
		my %seen_chroms = ();
		my %qc = ();
		
		
		while(<IN>) {
			chomp;
			
			@data = split /\s+/, $_;
			
			next if $exclude{$data[1]};
			
			
			if(($data[1] ne $sample) && (scalar keys %geno >= 1)) {
			
				print OUT $sample;
				
				if($args{'p'}) {
					print OUT "\t1\t0\t0\t0\t0";
				}
			
				foreach my $chrom(sort {$a <=> $b} keys %$snps) {
					next if $chrom =~ /chrom/i;
					
					foreach my $snp(@{$order{$chrom}}) {
						
						if($args{'p'}) {
							$geno = ($geno{$snp} ? $geno{$snp} : "NN");
							
							if(defined $args{'qcg'}) {
								$geno = "NN" unless $qc{$snp} > $args{'qcg'};
								#print "QC Check: $qc{$snp} \? $args{'qcg'}\n";
							}
							
							if($args{'qcl'}) {
								$geno = "NN" unless $qc{$snp} < $args{'qcl'};
							}
							
							$geno = substr($geno,0,1)." ".substr($geno,1,1);
							
							if($args{'1'}) {
								$geno =~ tr/NACGT/01234/;
							}
							
							
							print OUT "\t$geno";
						}
						
						# alter the data for this point if the sample is male and this is the X chromosome
						else {
							print OUT "\t".($geno{$snp} ? $geno{$snp} : "NN");
						}
					}
				}
				
				print OUT "\n";
				
				%seen_chroms = ();
				%geno = ();
				%qc = ();
			}
			
			$geno{$data[0]} = $data[2];
			$qc{$data[0]} = $data[3];
			$sample = $data[1];
			$seen_chroms{$chrom{$data[0]}} = 1;
		}
	
		close IN;
		
		print OUT $sample;
				
		if($args{'p'}) {
			print OUT "\t1\t0\t0\t0\t0";
		}
		
		# write out the rest of the data
		foreach my $chrom(sort {$a <=> $b} keys %$snps) {
			next if $chrom =~ /chrom/i;
					
			foreach my $snp(@{$order{$chrom}}) {
				
				if($args{'p'}) {
					$geno = ($geno{$snp} ? $geno{$snp} : "NN");
					
					if(defined $args{'qcg'}) {
						$geno = "NN" unless $qc{$snp} > $args{'qcg'};
						#print "QC Check: $qc{$snp} \? $args{'qcg'}\n";
					}
					
					if($args{'qcl'}) {
						$geno = "NN" unless $qc{$snp} < $args{'qcl'};
					}
					
					$geno = substr($geno,0,1)." ".substr($geno,1,1);
					
					if($args{'1'}) {
						$geno =~ tr/NACGT/01234/;
					}
					
					
					print OUT "\t$geno";
				}
				
				# alter the data for this point if the sample is male and this is the X chromosome
				else {
					print OUT "\t".($geno{$snp} ? $geno{$snp} : "NN");
				}
			}
		}
			
		print OUT "\n";
	}
	
	close OUT;
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
