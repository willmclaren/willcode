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

foreach $sample(keys %hets) {
	%counts = ();

	foreach $snp(keys %{$hets{$sample}}) {
		$pos = $pos{$snp};
		$chr = $chrom{$snp};
		
		$region = $chr."_".(int ($pos / $size));
		
		$counts{$region}++;
	}
	
	$none = 0;
	$low = 0;
	$mid = 0;
	$high = 0;
	$total = 0;
	
	foreach $region(keys %counts) {
		if($counts{$region} <= 1) {
			$low += $counts{$region};
		}
		
		elsif($counts{$region} <= 3) {
			$mid += $counts{$region};
		}
		
		else {
			$high += $counts{$region};
		}
		
		$total += $counts{$region}
	}
	
	print "$sample\t$low\t$mid\t$high\t".(($high/$total)*100)."\n";
}