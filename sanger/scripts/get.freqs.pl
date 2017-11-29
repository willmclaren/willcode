#!/usr/bin/perl

$args{'o'} = "default";

# define a list of arguments that have values to shift
%args_with_vals = (
	'f' => 1,
	'g' => 1,
	'o' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

@pop_order = qw/CEU CHB JPT YRI CHB+JPT/;


# GET GENOTYPE DATA
###################

open IN, $args{'g'} or die ($args{'g'} ? "Could not open genotype file $args{'g'}\n" : "Genotype file not specified - use -g genotype_file\n");

debug("Loading genotype data from $args{'g'}");

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	
	# work out which is the rare allele
	$common = substr($data[5],0,1);
	$het = $data[4];
	
	$rare = $het;
	$rare =~ s/$common//g;
	
	$rare{$snp} = $rare;
}

close IN;




# GET FREQUENCY DATA
####################

open IN, $args{'f'} or die ($args{'f'} ? "Could not open frequency file $args{'f'}\n" : "Frequency file not specified - use -f freq_file\n");

debug("Loading frequency data from $args{'f'}");

SNP: while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	next unless $rare{$snp};
	
	foreach $pop(@pop_order) {
		$allele_a = shift @data;
		$freq_a = shift @data;
		$allele_b = shift @data;
		$freq_b = shift @data;
		
		if((join "", (sort ($allele_a, $allele_b))) =~ /AT|CG/i) {
			#delete $list{$snp};
			$excluded{$snp} = 1;
			next SNP;
		}
		
		$freqs{$snp}{$pop}{$allele_a} = $freq_a;
		$freqs{$snp}{$pop}{$allele_b} = $freq_b;
	}
}

close IN;

$outfile = $args{'o'}.".freqs";
	
debug("Writing to $outfile\n");

open OUT, ">$outfile";


while(<>) {
	chomp;
	
	($snp, $sample, $geno, $qual) = split /\t/, $_;
	
	next unless $freqs{$snp};
	
	print OUT "$snp\t$freqs{$snp}{'CEU'}{$rare{$snp}}\t$freqs{$snp}{'CHB'}{$rare{$snp}}\t$freqs{$snp}{'JPT'}{$rare{$snp}}\t$freqs{$snp}{'YRI'}{$rare{$snp}}\n";
}

close OUT;


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