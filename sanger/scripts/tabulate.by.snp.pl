#!/usr/bin/perl

$file = pop @ARGV;

@snps = @ARGV;

open IN, $file or die "Could not open file $file\n";

$header = <IN>;
chomp $header;

@order = split /\s+/, $header;
shift @order;
shift @order;

for $i(0..$#order) {
	$order{$order[$i]} = $i;
}

open OUT, ">debug";

while(<IN>) {
	chomp;
	
	$_ =~ s/\-/0/g;
	
	@data = split /\s+/, $_;
	
	shift @data;
	$trans = shift @data;
	
	$type = $data[$order{"hla_drb1"}]." ".$data[$order{"hla_dqa1"}]." ".$data[$order{"hla_dqb1"}];
	
	@allele = ();
	
	$nosnpcounts{$type}{$trans}++;
	
	for $i(0..$#snps) {
		$snp = $snps[$i];
		
		push @allele, $data[$order{$snp}];
		
		@outallele = @allele;
		
		for $j(($i+1)..$#snps) {
			push @outallele, "-";
		}
		
		$counts{$type}{(join "\t", @outallele)}{$trans}++;
		
		print OUT (join " ", @outallele);
		print OUT "\t$type\t$trans\n";
		
		$obs{(join "\t", @outallele)} = 1;
	}
}

print "DRB1\tDQA1\tDQB1";

foreach $snp(@snps) {
	print "\t$snp";
}

print "\tTrans\tNot\n";

foreach $type(sort keys %counts) {
	$otype = $type;
	$otype =~ s/ /\t/g;
	
	print "$otype";
	for(1..(scalar @snps)) {
		print "\t-";
	}
	print "\t".($nosnpcounts{$type}{1} ? $nosnpcounts{$type}{1} : 0)."\t".($nosnpcounts{$type}{0} ? $nosnpcounts{$type}{0} : 0)."\n";

	foreach $allele(sort keys %{$counts{$type}}) {
		
		print "$otype\t$allele";
	
		foreach $status(1,0) {
			print "\t".($counts{$type}{$allele}{$status} ? $counts{$type}{$allele}{$status} : 0);
		}
		
		print "\n";
	}
}