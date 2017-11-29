#!/usr/bin/perl

$args{'o'} = 'RHHhaplo';
$args{'t'} = 0.01;

%args_with_vals = (
	'b' => 1,
	'm' => 1,
	's' => 1,
	'o' => 1,
	't' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# SAMPLES
open IN, $args{'s'} or die ($args{'s'} ? "Could not read from file $args{'s'}\n" : "No sample list file specifed (-s)\n");

print "Reading from sample file $args{'s'}\n";

while(<IN>) {
	chomp;
	push @samples, (split /\s+/, $_)[0];
}
close IN;

# SNPS
open IN, $args{'m'} or die ($args{'m'} ? "Could not read from file $args{'m'}\n" : "No SNP list file specifed (-m)\n");

print "Reading from marker file $args{'m'}\n";

while(<IN>) {
	chomp;
	push @snps, (split /\s+/, $_)[0];
}
close IN;

# BLOCKS
foreach $blockfile(split /\,/, $args{'b'}) {
	
	open IN, $blockfile or die ($blockfile ? "Could not read from file $blockfile\n" : "No block file specifed (-b)\n");
	
	print "Reading from block file $blockfile\n";
	
	while(<IN>) {
		chomp;
		
		if(/BLOCK/) {
			@data = split /\s+/, $_;
			
			$block = $data[1];
			$block =~ s/\.//;
			
			$block += $prev_block if $prev_block;
			
			while($data[-1] =~ /\d/) {
				$num = pop @data;
				$num += $prev_snp if $prev_snp;
				$use{$snps[$num-1]} = 1;
				unshift @{$blocks{$block}}, $num;
			}
	 		#print "$block\t@{$blocks{$block}}\n";
		}
		
		$in = '';
		
		while($in !~ /Multi/i) {
			$in = <IN> || last;
			
# 			@data = split /\s+/, $in;
# 			
# 			$allele = shift @data;
# 			$freq = shift @data;
# 			
# 			$freq =~ s/\(|\)//g;
			
			#$freqs{$block}{$allele} = $freq;
		}
	}
	close IN;
	
	$prev_block = $block;
	$prev_snp = $blocks{$block}[-1];
}

#die;
#
print "Reading data\n";

# DATA
while(<>) {
	next unless /^m/i;
	
	chomp;
	
	@data = split /\s+/, $_;
	
	shift @data;
	
	$snp = shift @data;
	
	next unless $use{$snp};
	
	foreach $sample(0..$#samples) {
	#foreach $sample(@samples) {
		$a = shift @data or die "Number of samples (".(scalar @samples).") does not correspond to number of data columns (A)\n";
		$b = shift @data or die "Number of samples (".(scalar @samples).") does not correspond to number of data columns (B)\n";

		$data{$sample}{$snp} = "$a $b";#{'a'} = $a;
# 		$data{$sample}{$snp}{'b'} = $b;
	}
}

print "Calculating haplotypes\n";

open HAP, ">".$args{'o'}."_haplotypes";
open FULL, ">".$args{'o'}."_full.dist";
open GENO, ">".$args{'o'}."_genotype.dist";


foreach $block(sort {$a <=> $b} keys %blocks) {
	foreach $sample(0..$#samples) {
		$haplo_a = '';
		$haplo_b = '';
		
		foreach $snp_num(@{$blocks{$block}}) {
			$snp = $snps[$snp_num-1];
			
			($a, $b) = ($data{$sample}{$snp} ? (split / /, $data{$sample}{$snp}) : (0, 0));
			$haplo_a .= $a;
			$haplo_b .= $b;
		
			delete $data{$sample}{$snp};
		}
		
		if($haplo_a !~ /0/) {
			$total{$block}++;
			$counts{$block}{$haplo_a}++;
		}
		
		if($haplo_b !~ /0/) {
			$total{$block}++;
			$counts{$block}{$haplo_b}++;
		}
		
		print HAP "$block\t$samples[$sample]\t$haplo_a\t$haplo_b\n";
		
		$geno{$sample} = $haplo_a." ".$haplo_b;
	}

	$foundrare = 0;

	foreach $allele(keys %{$counts{$block}}) {
		if($counts{$block}{$allele}/$total{$block} < $args{'t'}) {
			$foundrare = 1;
			$rare{$block}{$allele} = 1;
		}
	}

	if($foundrare) {
		foreach $sample(keys %geno) {
			$strand = 0;
		
			foreach $allele(split / /, $geno{$sample}) {
				if($rare{$block}{$allele}) {
					$rarecounts{$sample}++;
					print FULL
						"$samples[$sample]\t".
						"$block\t".
						#"$allele\t".
						($strand ? "B" : "A")."\t".
						"RARE\t".
						"$snps[$blocks{$block}[0]]\t$snps[$blocks{$block}[-1]]\n";
				}
				
				$strand++;
			}
		}
	}
	
	foreach $allele(keys %{$counts{$block}}) {
		print GENO "$block\t$allele\t$counts{$block}{$allele}\t$total{$block}\t".($counts{$block}{$allele}/$total{$block})."\n";
	}
}

close HAP;
close GENO;
close FULL;


open SAM, ">".$args{'o'}."_sample.dist";

for $sample(0..$#samples) {
	print SAM "$samples[$sample]\t".($rarecounts{$sample} ? $rarecounts{$sample} : 0)."\n";
}

close SAM;