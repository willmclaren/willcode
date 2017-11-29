#!/usr/bin/perl

#use strict;
use Tie::File;

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
my %args_with_vals = (
	'o' => 1,
	'e' => 1,
	's' => 1,
	'ni' => 1,
);

# define a usage message
my $usage =<<END;
Usage: perl prep.fastphase.pl [options]

-----------------------------------------------------------

List of options requiring an argument:
	-s	File containing marker information
		(i.e. chromosome, position etc.)
	-e	File containing a list of samples to exclude
	-o	Stem for output files

-----------------------------------------------------------
			
List of options without an argument (i.e. flags)
	
	-ni	Number of individuals
	-p	Make files for use in PHASE
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
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

unless($args{'ni'}) {
	die "You must specify the number of individuals with -ni\n";
}



# LOAD SNP REFERENCE DATA IF GIVEN
##################################

our $snps;
our %chrom;


if($args{'s'}) {

	my $file = $args{'s'};
	
	debug("Reading SNP reference data from ".$file);
	
	open IN, $file or die "Could not open markers file ".$file."\n";
	
	my @data;
	
	while(<IN>) {
	
		# skip this line unless it has numerical data on it
		next unless /\d/;
		
		chomp;
		
		@data = split /\s+/, $_;
		
		# try and guess the format of the file to parse it
		if(scalar @data == 4) {
			$snps{$data[0]}{$data[3]} = $data[1];
			$chroms{$data[1]} = $data[0];
		}
		
		elsif(/Infinium/) {
			$snps{$data[3]}{$data[4]} = $data[0];
			$chroms{$data[0]} = $data[3];
		}
		
		else {
			$snps{$data[1]}{$data[2]} = $data[0];
			$chroms{$data[0]} = $data[1];
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

debug("Writing to output files ".($args{'o'} ? $args{'o'} : "fastphase")."_chr\*.inp");

foreach $chrom(keys %snps) {
	# open an output file
	open OUT, ">".($args{'o'} ? $args{'o'} : "fastphase")."_chr$chrom.inp";
	
	print OUT $args{'ni'}."\n".(scalar keys %{$snps{$chrom}})."\n";
	print OUT "P";
	
	foreach $pos(sort {$a <=> $b} keys %{$snps{$chrom}}) {
		print OUT "\t$pos";
		push @line, "S" if $args{'p'};
	}
	
	print OUT "\n";
	
	print OUT (join "\t", @line) if $args{'p'};
	print OUT "\n" if $args{'p'};
	
	close OUT;
}

debug("Reading data");

while(<>) {
	chomp;
	
	($snp, $samp, $geno, $crap) = split /\t/, $_;
	
	next unless $chroms{$snp};
	next if (scalar keys %exclude && $exclude{$samp});
	
	$geno =~ s/N/\?/g;
	
	if($samp ne $prev) {
		output(\%data, $prev, \%chroms_seen);
		%data = ();
		%chroms_seen = ();
	}
	
	$data{$snp} = $geno;
	$chroms_seen{$chroms{$snp}} = 1;
	
	$prev = $samp;
}

debug("Found data for ".(scalar keys %chroms_seen)." chromosomes\n");

output(\%data, $samp, \%chroms_seen);

close OUT;

debug("Finished");


# OUTPUT SUBROUTINE
###################

sub output {
	my ($data, $samp, $chromss) = @_;
	
	#debug("Doing output");
	
	foreach my $chrom(keys %$chromss) {
		open OUT, ">>".($args{'o'} ? $args{'o'} : "fastphase")."_chr$chrom.inp";
		
		#debug("Writing to ".($args{'o'} ? $args{'o'} : "fastphase")."_chr$chrom.inp");
		
		print OUT $samp."\n";
	
		my @line_a = ();
		my @line_b = ();
		my $snp;
		
		foreach $pos(sort {$a <=> $b} keys %{$snps{$chrom}}) {
			$snp = $snps{$chrom}{$pos};
			push @line_a, ($data->{$snp} ? substr($data->{$snp},0,1) : "?");
			push @line_b, ($data->{$snp} ? substr($data->{$snp},1,1) : "?");
		}
		
		print OUT (join "\t", @line_a);
		print OUT "\n";
		print OUT (join "\t", @line_b);
		print OUT "\n";
		
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
