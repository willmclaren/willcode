#!/usr/bin/perl

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = $data[2];
	$snp = $data[0];
	$call = $data[1];
	$allele_a = $data[10];
	$height_a = $data[9];
	
	$allele_b = $data[12];
	$height_b = $data[11];
	
	#$snp =~ s/^.?rs/rs/g;
	
	$allele_a =~ s/^allele\-//g;
	$allele_a =~ s/\-$//g;
	$allele_b =~ s/^allele\-//g;
	$allele_b =~ s/\-$//g;
	
	$height_a =~ s/^ht\-//g;
	$height_a =~ s/\-$//g;
	$height_b =~ s/^ht\-//g;
	$height_b =~ s/\-$//g;
	
	#print "Cheese\t$height_a\t$height_b\t$allele_a\t$allele_b\n";
	
	$data{$snp}{$sample}{$allele_a} = $height_a;
	$data{$snp}{$sample}{$allele_b} = $height_b;
	
	$seenalleles{$snp}{$allele_a} = 1;
	$seenalleles{$snp}{$allele_b} = 1;
	$calls{$snp}{$sample} = $call;
}

print "SNP\tSample\tCall\tAllele_a\tHeight_a\tAllele_b\tHeight_b\n";

foreach $snp(keys %data) {
	foreach $sample(keys %{$data{$snp}}) {
		print "$snp\t$sample\t".(length($calls{$snp}{$sample}) == 1 ? $calls{$snp}{$sample}.$calls{$snp}{$sample} : $calls{$snp}{$sample});
	
		foreach $seen(sort keys %{$seenalleles{$snp}}) {
			print "\t$seen\t".($data{$snp}{$sample}{$seen} ? $data{$snp}{$sample}{$seen} : 0);
		}
		
		print "\n";
	}
}