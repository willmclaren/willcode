#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $shit, $pos) = split /\s+/, $_;
	push @snps, $snp;
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	for(1..3) {
		shift @data;
	}
	
	$gender{$sample} = shift @data;
	$trans{$sample} = shift @data;
	$trans{$sample} =~ s/\-9/\-/;
	
	push @samples, $sample;
	
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
		$g = join "", sort {$a <=> $b} ($a, $b);
		$g = 0 if $g =~ /0/;
	
		$data{$sample}{$snp} = $g;
		$seen{$snp}{$g} = 1 if $data{$sample}{$snp} !~ /0/;
	}
}

foreach $snp(@snps) {
	@seen = keys %{$seen{$snp}};
	
	if(scalar @seen == 1) {
		$conv{$snp}{$seen[0]} = 0;
	}
	
	if(scalar @seen == 2) {
		if(isHom($seen[0]) && isHom($seen[1])) {
			$conv{$snp}{$seen[0]} = 0;
			$conv{$snp}{$seen[1]} = 2;
		}
		
		else {
			if(isHom($seen[0])) {
				$conv{$snp}{$seen[0]} = 0;
				$conv{$snp}{$seen[1]} = 1;
			}
			
			else {
				$conv{$snp}{$seen[1]} = 0;
				$conv{$snp}{$seen[0]} = 1;
			}
		}
	}
	
	else {
		$c = 0;
		
		foreach $seen(@seen) {
			if(isHom($seen)) {
				$conv{$snp}{$seen} = $c;
				$c = 2;
			}
			
			else {
				$conv{$snp}{$seen} = 1;
			}
		}
	}
	
	$conv{$snp}{'0'} = '-';
}

$head = "Sample\tTranstatus\t".(join "\t", @snps);

print "$head\n";

foreach $s(@samples) {
	print $s."\t".$trans{$s};
	
	foreach $snp(@snps) {
		print "\t".$conv{$snp}{$data{$s}{$snp}};
		
		#print "\t".($data{$s}{$snp} ? ($conv{$snp}{$data{$s}{$snp}}) + 1 : "-");
	}
	
	print "\n";
}


sub isHom() {
	my $a = shift;
	
	return 1 if substr($a,0,1) eq substr($a,1,1);
}