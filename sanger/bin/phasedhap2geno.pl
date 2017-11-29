#!/usr/bin/perl

%args_with_vals = (
	'l' => 1,
	's' => 1,
	'p' => 1,
	'o' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}



open IN, $args{'s'} or die "Could not open sample file $args{'s'}\n";
while(<IN>) {
	chomp;
	push @samples, (split /\s+/, $_)[0];
}
close IN;


open IN, $args{'l'} or die "Could not open SNP legend file $args{'l'}\n";
while(<IN>) {
	chomp;
	
	next if /^rs$/;
	next if /position/;
	($snp, $pos, $a, $b) = split /\s+/, $_;
	
	push @snps, $snp;
	
	$legend{$snp}{0} = $a;
	$legend{$snp}{1} = $b;
}
close IN;


open IN, $args{'p'} or die "Could not open genotype data file $args{'p'}\n";
open OUT, ">$args{'o'}\.g" if $args{'o'};

$samplenum = 0;

while(<IN>) {
	chomp;
	@chr_a = split /\s+/, $_;
	
	$c = <IN>;
	chomp $c;
	@chr_b = split /\s+/, $c;
	
	$sample = $samples[$samplenum];
	$snpnum = 0;
	
	while(@chr_a) {
		$snp = $snps[$snpnum];
		$allele_a = $legend{$snp}{shift @chr_a};
		$allele_b = $legend{$snp}{shift @chr_b};
		
		$geno = join "", sort ($allele_a, $allele_b);
		$geno =~ s/\-/N/g;
		while(length($geno) < 2) {
			$geno .= "N";
		}
		
		$geno = 'NN' if $geno =~ /n/i;
		
		if($args{'o'}) {
			print OUT "$snp\t$sample\t$geno\t1\n";
		}
		
		else {
			print "$snp\t$sample\t$geno\t1\n";
		}
		
		$snpnum++;
	}
	
	$samplenum++;
}

close OUT if $args{'o'};
close IN;