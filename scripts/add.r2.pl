#!/usr/bin/perl

use strict;

my $lddir = "/lustre/work1/sanger/ns6/public_data/HapMap/PairWiseLD/";

my %args_with_vals = (
	'r' => 1,
	's' => 1,
);

#process arguments
my %args;

while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# sort out where we are looking for r2 values
my @ldfiles;

if(!defined $args{'r'}) {
	warn "No LD files specified with -r; looking for files in $lddir\n";

	opendir(LDDIR, $lddir) or die "Could not find LD directory $lddir\n";
	@ldfiles = grep !/^\.\.?\z/, (grep /genotypes/, readdir LDDIR);
	
	for my $i(0..$#ldfiles) {
		$ldfiles[$i] = $lddir.($lddir =~ /\/$/ ? "" : "\/").$ldfiles[$i];
	}
}

else {
	@ldfiles = split /\,/, $args{'r'};
}


# check a ref SNP has been specified
die "You must specify a reference SNP using -s\n" unless defined $args{'s'};
my $snp = $args{'s'};


my @data;
my %r;

# now search for the SNP in the r2 files
foreach my $file(@ldfiles) {
	open LD, $file or die "Could not read from $file\n";
	
	while(<LD>) {
		next unless /$snp\s+/;
		
		@data = split /\s+/, $_;
		
		# first 2 options guess at Haploview-type file
		if($data[0] eq $snp) {
			$r{$data[1]} = $data[4];
		}
		
		elsif($data[1] eq $snp) {
			$r{$data[0]} = $data[4];
		}
		
		
		# next 2 assume from-HapMap-website-type file
		elsif($data[3] eq $snp) {
			$r{$data[4]} = $data[6];
		}
		
		elsif($data[4] eq $snp) {
			$r{$data[3]} = $data[6];
		}
	}
	
	close LD;
	
	last if scalar keys %r >= 1;
}

# check we found some LD data
die "No LD data for $args{'s'} found\n" unless scalar keys %r > 0;


my $count;

while(<>) {
	chomp;

	# check if this is a header row
	if(/^SNP\t/) {
		print "$_\tRSQR\n";
		next;
	}
	
	@data = split /\s+/, $_;
	
	print "$_\t".($r{$data[0]} ? $r{$data[0]} : "-");
	print "\n";
	$count++;
}

die "No data given!\n" unless $count > 0;