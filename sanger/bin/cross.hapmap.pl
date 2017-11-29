#!/usr/bin/perl

# ARGUMENTS AND SETUP
#####################

%args_with_vals = (
	'l' => 1,
	'l1' => 1,
	'p1' => 1,
	's1' => 1,
	'l2' => 1,
	'p2' => 1,
	's2' => 1,
	'i1' => 1,
	'i2' => 1,
	'o' => 1,
	'r' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}





# LOAD DATA
###########

# load a list of SNPs to output
if($args{'l'}) {
	print "Loading SNP list\n";
	
	if($args{'l'} =~ /\.gz$/) {
		open IN, "gzcat ".$args{'l'}." | ";
	}
	
	else {
		open IN, $args{'l'};
	}
	
	while(<IN>) {
		chomp;
		
		$output_snps{(split /\s+/, $_)[0]} = 1;
	}
	
	close IN;
}


# load sample info files
die "No sample info files specified\n" unless ($args{'s1'} && $args{'s2'});

print "Reading sample info files\n";

if(!-e $args{'s1'}) {
	die "Could not open file $args{'s1'}\n";
}

elsif($args{'s1'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'s1'}." | ";
}

else {
	open IN, $args{'s1'};
}

while(<IN>) {
	chomp;
	push @samples_a, (split /\s+/, $_)[0];
}
close IN;




if(!-e $args{'s2'}) {
	die "Could not open file $args{'s2'}\n";
}

elsif($args{'s2'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'s2'}." | ";
}

else {
	open IN, $args{'s2'};
}
while(<IN>) {
	chomp;
	push @samples_b, (split /\s+/, $_)[0];
}
close IN;


# if($args{'r'}) {
# 	$args{'i1'} = 1+int(rand(60));
# 	$args{'i2'} = 1+int(rand(60));
# }

# load SNP info files
die "No SNP legend files specified\n" unless $args{'l1'} && $args{'l2'};

print "Reading SNP legend files\n";


if(!-e $args{'l1'}) {
	die "Could not open file $args{'l1'}\n";
}

elsif($args{'l1'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'l1'}." | ";
}

else {
	open IN, $args{'l1'};
}
while(<IN>) {
	chomp;
	next if /^rs$/;
	next if /position/;
	($snp, $pos, $a, $b) = split /\s+/, $_;
	push @snps_a, $snp;
	
	$pos{$snp} = $pos;
	
	$info_a{$snp}{0} = $a;
	$info_a{$snp}{1} = $b;
}
close IN;




if(!-e $args{'l2'}) {
	die "Could not open file $args{'l2'}\n";
}

elsif($args{'l2'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'l2'}." | ";
}

else {
	open IN, $args{'l2'};
}
while(<IN>) {
	chomp;
	next if /^rs$/;
	next if /position/;
	($snp, $pos, $a, $b) = split /\s+/, $_;
	push @snps_b, $snp;
	
	$pos{$snp} = $pos;
	
	$info_b{$snp}{0} = $a;
	$info_b{$snp}{1} = $b;
}
close IN;




# get a minimal set of SNPs to read data for
foreach $snp(@snps_a) {
	$final_snp_list{$snp}++;
}
foreach $snp(@snps_b) {
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



die "No phased data specified\n" unless $args{'p1'} && $args{'p2'};

# load phased data from population 1
if(!-e $args{'p1'}) {
	die "Could not open file $args{'p1'}\n";
}

elsif($args{'p1'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'p1'}." | ";
}

else {
	open IN, $args{'p1'};
}

print "Reading data for individual $args{'i1'} from population 1\n";

$samplenum = 0;

LINEA: while(<IN>) {

	chomp;
	
	$c = <IN>;
	
	
	if($args{'i1'}) {
		unless($samplenum == ($args{'i1'}-1)) {
			$samplenum++;
			next LINEA;
		}
	}
	
	chomp $c;
	@chr_a = split /\s+/, $_;
	@chr_b = split /\s+/, $c;
	
	
		
	$snpnum = 0;
	
	while(@chr_a) {
		$snp = $snps_a[$snpnum];
		$allele_a = shift @chr_a;
		$allele_b = shift @chr_b;
		
		if($final_snp_list{$snp}) {
			$data_a{$samplenum}{$snp}{'a'} = $allele_a;
			$data_a{$samplenum}{$snp}{'b'} = $allele_b;
			
			#print "P1 - s:$samplenum a:$data_a{$samplenum}{$snpnum}{'a'} b:$data_a{$samplenum}{$snpnum}{'b'}\n";
		}
		
		$snpnum++;
	}
	
	$samplenum++;
	
	last if ($args{'i1'} && ($samplenum >= $args{'i1'}));
}

close IN;

# load phased data from population 2
if(!-e $args{'p2'}) {
	die "Could not open file $args{'p2'}\n";
}

elsif($args{'p2'} =~ /\.gz$/) {
	open IN, "gzcat ".$args{'p2'}." | ";
}

else {
	open IN, $args{'p2'};
}
print "Reading data for individual $args{'i2'} from population 2\n";

$samplenum = 0;

LINEB: while(<IN>) {

	chomp;
	
	$c = <IN>;
	
	if($args{'i2'}) {
		unless($samplenum == ($args{'i2'}-1)) {
			$samplenum++;
			next LINEB;
		}
	}
	
	chomp $c;
	@chr_a = split /\s+/, $_;
	@chr_b = split /\s+/, $c;
		
	$snpnum = 0;
	
	while(@chr_a) {
		$snp = $snps_b[$snpnum];
		$allele_a = shift @chr_a;
		$allele_b = shift @chr_b;
		
		if($final_snp_list{$snp}) {
			$data_b{$samplenum}{$snp}{'a'} = $allele_a;
			$data_b{$samplenum}{$snp}{'b'} = $allele_b;
			
			#print "P2 - $snp s:$samplenum a:$allele_a b:$allele_b\n";
		}
		
		$snpnum++;
	}
	
	$samplenum++;
	
	last if ($args{'i2'} && ($samplenum >= $args{'i2'}));
}

close IN;



# read in recombination info file
if($args{'r'}) {

	print "Reading recombination info file\n";
	
	open IN, $args{'r'} or die "Could not open file $args{'r'}\n";
	while(<IN>) {
		chomp;
		next if /position/;
		
		($pos, $rate, $dist) = split /\s+/, $_;
		
		$recomb{$pos} = $dist;
	}
	close IN;
}




# STATUS CHECK
##############

print "Loaded data for:\n\t".(scalar keys %data_a)." individuals (population 1)\n\t".(scalar keys %data_b)." individuals (population 2)\n";

if(!$args{'i1'}) {
	print "Enter and invidual number from population 1: ";
	$args{'i1'} = <STDIN>;
	chomp $args{'i1'};
}

if(!$args{'i2'}) {
	print "Enter and invidual number from population 1: ";
	$args{'i2'} = <STDIN>;
	chomp $args{'i2'};
}


$a = $args{'i1'};
$b = $args{'i2'};
$a--; $b--;

$new_id = $samples_a[$a]."_".$samples_b[$b];

@ordered_snps = sort {$pos{$a} <=> $pos{$b}} keys %final_snp_list;


# CROSSING OVER
###############

if($args{'r'}) {
	
	if($args{'r1'} || ((!$args{'r1'}) && (!$args{'r2'}))) {
		print "Crossing over individual $args{'i1'} from population 1\n";
		
		$rec = 0;
		
		# do individual A
		foreach $snp_num(0..$#ordered_snps) {
			$snp = $ordered_snps[$snp_num];
			$pos = $pos{$snp};
			
			next unless $recomb{$pos};
		
			if($last_pos) {
				$dist = $recomb{$pos} - $last_dist;
				
				$num = rand(100);
				
				if($num < $dist) {
					for $i($snp_num..$#ordered_snps) {
						$temp = $data_a{$a}{$ordered_snps[$i]}{'a'};
						$data_a{$a}{$ordered_snps[$i]}{'a'} = $data_a{$a}{$ordered_snps[$i]}{'b'};
						$data_a{$a}{$ordered_snps[$i]}{'b'} = $temp;
					}
					
					push @recs, "\t$last_snp \($last_pos\) and $snp \($pos\) : $num $dist\n";
				
					$rec++;
				}
			}
			
			$last_pos = $pos;
			$last_snp = $snp;
			$last_dist = $recomb{$pos};
		}
		
		print "Simulated $rec recombination event\(s\):\n".(join "", @recs);
	}
	
	
	
	if($args{'r2'} || ((!$args{'r1'}) && (!$args{'r2'}))) {
		print "Crossing over individual $args{'i2'} from population 2\n";
		$rec = 0;
		@recs = ();
	
		# do individual B
		foreach $snp_num(0..$#ordered_snps) {
			$snp = $ordered_snps[$snp_num];
			$pos = $pos{$snp};
			
			next unless $recomb{$pos};
		
			if($last_pos) {
				$dist = $recomb{$pos} - $last_dist;
				
				$num = rand(100);
				
				if($num < $dist) {
					for $i($snp_num..$#ordered_snps) {
						$temp = $data_b{$b}{$ordered_snps[$i]}{'a'};
						$data_b{$b}{$ordered_snps[$i]}{'a'} = $data_b{$b}{$ordered_snps[$i]}{'b'};
						$data_b{$b}{$ordered_snps[$i]}{'b'} = $temp;
					}
					
					push @recs, "\t$last_snp \($last_pos\) and $snp \($pos\) : $num $dist\n";
				
					$rec++;
				}
			}
			
			$last_snp = $snp;
			$last_pos = $pos;
			$last_dist = $recomb{$pos};
		}
		
		print "Simulated $rec recombination event\(s\)\n".(join "", @recs);
	}
}




$count = 0;

# open OUT, ">".($args{'o'} ? $args{'o'} : "cross")."\.g";
# print "Writing to ".($args{'o'} ? $args{'o'} : "cross")."\.g\n";
# 
# foreach $snp(keys %final_snp_list) {
# 	print OUT "$snp\t$new_id\t";
# 	
# 	$geno = join "", sort ($info_a{$snp}{$data_a{$a}{$snp}{'a'}}, $info_b{$snp}{$data_b{$b}{$snp}{'a'}});
# 	$geno =~ s/\-/N/g;
# 	
# 	while(length($geno) < 2) {
# 		$geno .= "N";
# 	}
# 	
# 	$geno = 'NN' if $geno =~ /n/i;
# 	
# 	
# 	print OUT $geno;
# 	#print OUT "\t$data_a{$a}{$snp}{'a'} $data_b{$b}{$snp}{'a'}";
# 	print OUT "\t1\n";
# 	#last if $count++ > 10;
# }
# 



# OUTPUT PHASED DATA
####################

print "Writing phased data\n";

open OUT, ">".($args{'o'} ? $args{'o'} : $new_id)."\.phased";

# parent A

# randomise which chromosome to pass on
$num = rand(10);
$chrom_to_pass = ($num > 5 ? 'a' : 'b');
print "Passing on chromsome $chrom_to_pass from parent A\n";

$first = 1;

foreach $snp(@ordered_snps) {
	print OUT ($first ? "" : " ").$data_a{$a}{$snp}{$chrom_to_pass};
	$first = 0;
}
print OUT "\n";


# parent B

# randomise which chromosome to pass on
$num = rand(10);
$chrom_to_pass = ($num > 5 ? 'a' : 'b');
print "Passing on chromsome $chrom_to_pass from parent B\n";

$first = 1;

foreach $snp(@ordered_snps) {
	print OUT ($first ? "" : " ").$data_b{$b}{$snp}{$chrom_to_pass};
	$first = 0;
}
print OUT "\n";

close OUT;




print "Writing auxilliary data\n";

# OUTPUT SAMPLE INFO
####################

open OUT, ">".($args{'o'} ? $args{'o'} : $new_id)."\.sample";
print OUT "$new_id\n";
close OUT;



# MAKE SNP LEGEND
#################

open OUT, ">".($args{'o'} ? $args{'o'} : $new_id)."\.legend";
foreach $snp(@ordered_snps) {
	print OUT "$snp $pos{$snp} $info_a{$snp}{'0'} $info_a{$snp}{'1'}\n";
}
close OUT;