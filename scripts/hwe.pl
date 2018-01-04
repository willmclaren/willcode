#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl/';
use Statistics::Distributions qw (chisqrprob);

if($ARGV[0] =~ /^\d+$/) {
	print hwe(@ARGV)."\n";
}

else {
	while(<>) {
		chomp;
		@data = split /\t/, $_;
		
		$snp = shift @data;
		
		print $snp."\t".hwe(@data)."\n";
	}
}

sub hwe() {
	my $hom_a = shift;
	my $het = shift;
	my $hom_b = shift;
	
	my $total = $hom_a + $het + $hom_b;
	
	# calculate frequecies
	my $q = ((2*$hom_b)+$het)/(2*$total);
	my $p = 1 - $q;
	
	# calculate expected values
	my $exp_a = $p * $p * $total;
	my $exp_h = 2 * $p * $q * $total;
	my $exp_b = $q * $q * $total;
	
	# calculate chi stat
	my $chi = 0;
	$chi += (($hom_a - $exp_a)*($hom_a - $exp_a))/$exp_a if $exp_a;
	$chi += (($het - $exp_h)*($het - $exp_h))/$exp_h if $exp_h;
	$chi += (($hom_b - $exp_b)*($hom_b - $exp_b))/$exp_b if $exp_b;
	
	my $df = 1;
	
	#print "$exp_a\t$exp_h\t$exp_b\t";
	
	return chisqrprob($df, $chi);
}