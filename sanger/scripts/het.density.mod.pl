#!/usr/bin/perl

# chromosome lengths
%length = (
	1 => "247249719",
	2 => "242951149",
	3 => "199501827",
	4 => "191273063",
	5 => "180857866",
	6 => "170899992",
	7 => "158821424",
	8 => "146274826",
	9 => "140273252",
	10 => "135374737",
	11 => "134452384",
	12 => "132349534",
	13 => "114142980",
	14 => "106368585",
	15 => "100338915",
	16 => "88827254",
	17 => "78774742",
	18 => "76117153",
	19 => "63811651",
	20 => "62435964",
	21 => "46944323",
	22 => "49691432",
	'X' => "154913754",
	'Y' => "57772954"
);

# calculate total genome size
foreach $len(values %length) { $genome_size += $len; }


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chrom, $pos) = split /\t/, $_;
	
	$snps{$chrom}{$pos} = $snp;
	$chrom{$snp} = $chrom;
	$pos{$snp} = $pos;
}

close IN;


while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$hets{$data[0]}{$data[1]} = 1;
}

$size = 5000000;

# generate regions
foreach $chr(1..22) {
	$a = 1;
	
	while($a < $length{$chr}) {
		$region = $chr."_".(int ($a / $size));
		push @regions, $region;
		$a += $size;
	}
}

foreach $sample(keys %hets) {
	%counts = ();
	
	$total_counts = scalar keys %{$hets{$sample}};
	$mean_region_count = $total_counts / (scalar @regions);
	
	foreach $snp(keys %{$hets{$sample}}) {
		$pos = $pos{$snp};
		$chr = $chrom{$snp};
		
		$region = $chr."_".(int ($pos / $size));
		
		$counts{$region}++;
	}
	
	$high = 0;
	$low = 0;
	$num = 0;
	@list = ();
	
	foreach $region(@regions) {
		$count = $counts{$region};
		
		push @list, $counts{$region};
	
		$ratio = $count / $mean_region_count;
		
		if($ratio > 4) {
			$high += $count;
		}
		
		if($ratio < 0.2) {
			$low++;
		}
	}
	
	$tot = 0;
	
	foreach $point(@list) {
		$tot += (($point - $mean_region_count)*($point - $mean_region_count));
	}
	
	$var = $tot / (scalar @data);
	$sd = sqrt($var);
	
	#print "Old = $mean_region_count\; New = ".($total_counts/$num)."\n";
	
	print "$sample\t".(100*$high/$total_counts)."\t".(100*$low/(scalar @regions))."\t$sd\n";
}