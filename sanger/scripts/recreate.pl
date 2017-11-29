#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @snps, (split /\s+/, $_)[0];
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($id, $chrom) = split /\t/, $_;
	
	$chroms{$id}{$chrom} = 1;
}

close IN;


while(<>) {
	chomp;
	
	($id, $chrom, $seq) = split /\t|\_/, $_;
	
	next unless $chroms{$id};
	
	$snpnum = 0;
	
	foreach $a(split //, $seq) {
		$snp = $snps[$snpnum];
		$snpnum++;
		
		next if $a =~ /\-/;
		
		$data{$id}{$chrom}{$snp} = $a;
		$use{$snp} = 1;
	}
}


open OUT, ">beagle";

foreach $snp(keys %use) {
	print OUT "M $snp";
	
	foreach $id(sort {$a <=> $b} keys %data) {
		foreach $chrom(sort keys %{$data{$id}}) {
			print OUT " $data{$id}{$chrom}{$snp}";
		}
	}
	
	print OUT "\n";
}

close OUT;


open OUT, ">trait";

print OUT "A T1D";

foreach $id(sort {$a <=> $b} keys %data) {
	foreach $chrom(sort keys %{$data{$id}}) {
		print OUT " ".($chroms{$id}{$chrom} ? 2 : 1);
	}
}

print OUT "\n";

close OUT;