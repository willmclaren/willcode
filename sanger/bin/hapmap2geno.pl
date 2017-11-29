#!/usr/bin/perl

%args_with_vals = (
	'l' => 1,
	'p' => 1,
	's' => 1,
	'o' => 1,
	'i' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# load sample info files
die "No sample info files specified\n" unless ($args{'s'});

print "Reading sample info file\n";

open IN, $args{'s'} or die "Could not open file $args{'s'}\n";
while(<IN>) {
	chomp;
	push @samples, (split /\s+/, $_)[0];
}
close IN;



# load SNP info files
die "No SNP legend file specified\n" unless $args{'l'};

print "Reading SNP legend file\n";

open IN, $args{'l'} or die "Could not open file $args{'l'}\n";
while(<IN>) {
	chomp;
	next if /^rs$/;
	next if /position/;
	($snp, $pos, $a, $b) = split /\s+/, $_;
	push @snps, $snp;
	
	$info{$snp}{0} = $a;
	$info{$snp}{1} = $b;
}
close IN;

# load a list of SNPs to output
if($args{'i'}) {
	print "Loading SNP list\n";

	open IN, $args{'i'} or die "Could not open SNP list $args{'i'}\n";
	
	while(<IN>) {
		chomp;
		
		$output_snps{(split /\s+/, $_)[0]} = 1;
	}
	
	close IN;
}


# get a minimal set of SNPs to read data for
foreach $snp(@snps) {
	$final_snp_list{$snp}++;
}
foreach $snp(keys %output_snps) {
	$final_snp_list{$snp}++;
}

$max_count = (sort {$a <=> $b} values %final_snp_list)[-1];

foreach $snp(keys %final_snp_list) {
	delete $final_snp_list{$snp} unless $final_snp_list{$snp} == $max_count;
}

print "Found minimal common set of ".(scalar keys %final_snp_list)." SNPs\n";





die "No phased data specified\n" unless $args{'p'};

# load phased data from population 1
open IN, $args{'p'} or die "Could not open file $args{'p'}\n";

print "Reading data for population\n";

$samplenum = 0;

while(<IN>) {
	chomp;
	@chr_a = split /\s+/, $_;
	
	$c = <IN>;
	chomp $c;
	@chr_b = split /\s+/, $c;
		
	$snpnum = 0;
	
	while(@chr_a) {
		$snp = $snps[$snpnum];
		$allele_a = shift @chr_a;
		$allele_b = shift @chr_b;
		
		if($final_snp_list{$snp}) {
			$data{$samplenum}{$snp}{'a'} = $allele_a;
			$data{$samplenum}{$snp}{'b'} = $allele_b;
		}
		
		$snpnum++;
	}
	
	$samplenum++;
}

close IN;



$count = 0;

print "Writing to ".">".($args{'o'} ? $args{'o'} : "cross")."\.g";

open OUT, ">".($args{'o'} ? $args{'o'} : "cross")."\.g";


foreach $sample(keys %data) {
	
	foreach $snp(@snps) {
		print OUT "$snp\t@samples[$sample]\t";
		
		$geno = join "", sort ($info{$snp}{$data{$sample}{$snp}{'a'}}, $info{$snp}{$data{$sample}{$snp}{'b'}});
		$geno =~ s/\-/N/g;
		
		while(length($geno) < 2) {
			$geno .= "N";
		}
		
		$geno = 'NN' if $geno =~ /n/i;
		
		print OUT $geno;
		print OUT "\t1\n";
	}
}

close OUT;