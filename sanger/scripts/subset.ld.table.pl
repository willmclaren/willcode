#!/usr/bin/perl


# map file for matrix
$line_num = 0;

open IN, shift @ARGV;
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data <= 3) {
		$snp = $data[0];
	}
	
	elsif(scalar @data == 4) {
		$snp = $data[1];
	}
	
	push @snps, $snp;
	$order{$snp} = $line_num;
	$line_num++;
}

# training SNPs
open IN, shift @ARGV;
while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data <= 3) {
		$snp = $data[0];
	}
	
	elsif(scalar @data == 4) {
		$snp = $data[1];
	}
	
	if($order{$snp}) {
		$training{$snp} = 1;
		push @train, $order{$snp};
	}
}

$line_num = 0;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$snp_a = $snps[$line_num];
	
	$line_num++;
	
	# skip this if it is a training SNP
	next if $training{$snp_a};
	
	# skip it if it's neither
	#next unless $target{$snp_a};
	
# 	print "$snp training\n" if $training{$snp_a};
# 	print "$snp target\n" if $target{$snp_a};
		
	$max = -9;
		
	foreach $i(@train) {
		$r = $data[$i];
		$max = $r if (($r > $max) && ($r ne "nan"));
	}
	
	print $snp_a."\t$max\n";
}