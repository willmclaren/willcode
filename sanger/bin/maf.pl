#!/usr/bin/perl

if($ARGV[0] =~ /^\d+$/) {
	print maf(@ARGV)."\n";
}

else {
	while(<>) {
		chomp;
		@data = split /\t/, $_;
		
		$snp = shift @data;
		
		print $snp."\t".maf(@data)."\n";
	}
}

sub maf() {
	my $hom_a = shift;
	my $het = shift;
	my $hom_b = shift;
	
	my $total = $hom_a + $het + $hom_b;
	
	# calculate frequecies
	my $q = ((2*$hom_b)+$het)/(2*$total);
	my $p = 1 - $q;
	
	return ($p < $q ? $p : $q);
}