#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @hla, (split /\s+/, $_)[0];
}

close IN;


while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	
	foreach $hla(@hla) {
		$a = shift @data;
		$b = shift @data;
		
		$seen{$hla}{$a} = 1;
		$seen{$hla}{$b} = 1;
		
		$data{$fam}{$id}{$hla} = $a." ".$b;
	}
}

foreach $fam(keys %data) {
	foreach $id(keys %{$data{$fam}}) {
		print "$fam\t$id";
	
		foreach $hla(sort keys %seen) {
			($a, $b) = split / /, $data{$fam}{$id}{$hla};
			
			foreach $allele(sort keys %{$seen{$hla}}) {
				
				@out = ();
				
				push @out, ($a eq $allele ? 2 : 1);
				push @out, ($b eq $allele ? 2 : 1);
				
				print "\t".(join " ", @out);
			}
		}
		
		print "\n";
	}
}

open OUT, ">map";

foreach $hla(sort keys %seen) {
	foreach $allele(sort keys %{$seen{$hla}}) {
		print OUT "$hla\.$allele\n";
	}
}

close OUT;