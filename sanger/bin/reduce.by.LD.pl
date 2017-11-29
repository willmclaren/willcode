#!/usr/bin/perl

while($ARGV[0] =~ /\-/) {
	$arg = shift @ARGV;
	$arg =~ s/\-//g;
	
	$val = shift @ARGV;
	
	$args{$arg} = $val;
}

# set default r2 threshold
$r2_thresh = ($args{'r'} ? $args{'r'} : 1);

# set output file stem
$args{'o'} = ($args{'o'} ? $args{'o'} : "LD".$r2_thresh);

$geno_dist_file = shift @ARGV;

open IN, $geno_dist_file or die "Could not open distribution file $geno_dist_file\n";

debug("Reading genotype distribution from $geno_dist_file");

while(<IN>) {
	$snps{(split /\t/, $_)[0]} = 1;
}

close IN;

foreach $file(@ARGV) {
	open IN, $file or die "Could not open file $file\n";
	
	debug("Reading LD data from $file");
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		$snp_a = $data[3];
		$snp_b = $data[4];
		$r2 = $data[6];
		
		next unless $snps{$snp_a} && $snps{$snp_b};
		
		$linked{$snp_a}{$snp_b} = $r2 if $r2 >= $r2_thresh;
	}
	
	close IN;
}


debug("Removing linked SNPs with Rsqd >= $r2_thresh");

open REM, ">".$args{'o'}.".removed";

foreach $snp_a(sort {(scalar keys %{$linked{$b}}) <=> (scalar keys %{$linked{$a}})} keys %linked) {
	next if $deleted{$snp_b};

	foreach $snp_b(keys %{$linked{$snp_a}}) {
		print REM "$snp_a\t$snp_b\t$linked{$snp_a}{$snp_b}\n";
	
		delete $snps{$snp_b};
		delete $linked{$snp_b};
		$deleted{$snp_b} = 1;
	}
}

close REM;

debug((scalar keys %deleted)." removed SNPs written to ".$args{'o'}.".removed");

open IN, $geno_dist_file;
open OUT, ">".$args{'o'}."_genotype.dist";

debug("Writing new distribution to ".$args{'o'}."_genotype.dist");

while(<IN>) {
	$snp = (split /\t/, $_)[0];
	
	print OUT $_ if $snps{$snp};
}

close OUT;
close IN;


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