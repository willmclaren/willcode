#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	$switch{$_} = 1;
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$a{$data[0]} = $data[2];
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$b{$data[0]} = $data[2];
	
	$samp = $data[1];
}


foreach $snp(keys %a) {
	next unless $b{$snp};
	
	if($switch{$snp}) {
		$b{$snp} =~ tr/ACGT/TGCA/;
		$b{$snp} = join "", (sort split //, $b{$snp});
	}
	
	$total++;
	
	if("$a{$snp}$b{$snp}" =~ /N/) {
		$null++;
	}
	
	elsif($a{$snp} eq $b{$snp}) {
		$right++;
	}
	
	else {
		$wrong++;
	}
}

print "$samp\t$total\t$right\t$wrong\t$null\n";