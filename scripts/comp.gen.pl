#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	$snp = shift @data;
	
	$seen{$snp}++;
	
	if((scalar @data) == 8) {
		($ca, $cb, $cc, $ga, $gb, $gc, $n, $n2) = @data;
		
		$a{$snp}{$ga} = $ca if $ca > 0;
		$a{$snp}{$gb} = $cb if $cb > 0;
		$a{$snp}{$gc} = $cc if $cc > 0;
	}
	
	else {
		while(@data) {
			$g = shift @data;
			$c = shift @data;
			
			next unless $g =~ /A|C|G|T|1|2|3|4/;
			
			$a{$snp}{$g} = $c;
			
	# 		print "$snp $g $c\n";
		}
	}
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	$snp = shift @data;
	
	$seen{$snp}++;
	
	if((scalar @data) == 8) {
		($ca, $cb, $cc, $ga, $gb, $gc, $n, $n2) = @data;
		
		$b{$snp}{$ga} = $ca if $ca > 0;
		$b{$snp}{$gb} = $cb if $cb > 0;
		$b{$snp}{$gc} = $cc if $cc > 0;
	}
	
	else {
		while(@data) {
			$g = shift @data;
			$c = shift @data;
			
			next unless $g =~ /A|C|G|T|1|2|3|4/;
			
			$b{$snp}{$g} = $c;
			
	# 		print "$snp $g $c\n";
		}
	}
}

close IN;

$clunge = 0;

foreach $snp(keys %seen) {
	next unless ($a{$snp} && $b{$snp});
	$clunge++;
	
	$othera = '?';
	$otherb = '?';
	
	# look at set a
	$hom_a = 0;
	$heta = 0;
	$hom_b = 0;
	$max = -1;
	$total = 0;
	$hetga = 0;
	$maj_a = 0;
	
	foreach $g(keys %{$a{$snp}}) {
		if(isHet($g)) {
			$heta = $a{$snp}{$g};
			$hetga = $g;
		}
		
		elsif($hom_a) {
			$hom_b = $a{$snp}{$g};
			if($hom_b > $max) {
				$maj_a = $g;
				$max = $hom_b;
			}
		}
		
		else {
			$hom_a = $a{$snp}{$g};
			if($hom_a > $max) {
				$maj_a = $g;
				$max = $hom_a;
			}
		}
		
		$total += $a{$snp}{$g};
	}
	
	# calculate frequency
	$f_a = ($total ? ((2*$hom_a)+$heta)/(2*$total) : 0);
	$f_a = ($f_a > 0.5 ? 1 - $f_a : $f_a);
	
	
	# look at set b
	$hom_a = 0;
	$hetb = 0;
	$hom_b = 0;
	$max = -1;
	$total = 0;
	$hetgb = 0;
	$maj_b = 0;
	
	foreach $g(keys %{$b{$snp}}) {
		if(isHet($g)) {
			$hetb = $b{$snp}{$g};
			$hetgb = $g;
		}
		
		elsif($hom_a) {
			$hom_b = $b{$snp}{$g};
			if($hom_b > $max) {
				$maj_b = $g;
				$max = $hom_b;
			}
		}
		
		else {
			$hom_a = $b{$snp}{$g};
			if($hom_a > $max) {
				$maj_b = $g;
				$max = $hom_a;
			}
		}
		
		$total += $b{$snp}{$g};
	}
	
	# calculate frequency
	$f_b = ($total ? ((2*$hom_a)+$hetb)/(2*$total) : 0);
	$f_b = ($f_b > 0.5 ? 1 - $f_b : $f_b);
	
	
	# flagging
	$flag = 0;
	
	# flag if difference between frequencies is too great
	if(($f_a - $f_b > 0.1) || ($f_a - $f_b < -0.1)) {
		$flag = 1;
	}
	
	# flag if frequency close to 0.5
	if(($f_a > 0.475) || ($f_b > 0.475)) {
		$diff = $f_a - $f_b;
		$diff = 0 - $diff if $diff < 0;
		
		if($diff > 0.01) {
			$flag = 1;
		}
	}
	
	
	# resolve first alleles
	$ma = substr($maj_a, 0, 1);
	$mb = substr($maj_b, 0, 1);
	
	# resolve second allele in set a
	if($hetga) {
		foreach $a(split //, $hetga) {
			next unless $a =~ /\d|a|c|g|t/i;
			$othera = $a unless $maj_a =~ /$a/;
		}
	}
	
	elsif(scalar keys %{$a{$snp}} > 1) {
		foreach $g(keys %{$a{$snp}}) {
			next if $g eq $maj_a;
			next if isHet($g);
			$othera = substr($g,0,1);
		}
	}
	
	
	
	# resolve second allele in set b
	if($hetgb) {
		foreach $b(split //, $hetgb) {
			next unless $b =~ /\d|a|c|g|t/i;
			$otherb = $b unless $maj_b =~ /$b/;
		}
	}
	
	elsif(scalar keys %{$b{$snp}} > 1) {
		foreach $g(keys %{$b{$snp}}) {
			next if $g eq $maj_b;
			next if isHet($g);
			$otherb = substr($g,0,1);
		}
	}
	
	
	# resolve based on other set
	if((!$othera) && $otherb && ($maj_a eq $maj_b)) {
		$othera = $otherb;
	}
	
	if((!$otherb) && $othera && ($maj_a eq $maj_b)) {
		$otherb = $othera;
	}
	
	# try and resolve if flagged or not
	if($flag) {
		if(($maj_a eq $maj_b) && ($othera eq $otherb)) {
			$flag = 0;
		}
		
		else {
			$inv_maj_a = $maj_a;
			$inv_maj_a =~ tr/ACGT1234/TGCA4321/;
			
			$inv_othera = $othera;
			$inv_othera =~ tr/ACGT1234/TGCA4321/;
			
			if(($maj_b eq $inv_maj_a) && ($otherb eq $inv_othera)) {
				$flag = 0;
			}
		}
	}
	
	
	print "$snp\t$f_a\t$f_b\t$ma\t$othera\t$mb\t$otherb\t$flag\n";
}


print "SNPs seen: $clunge\n";

sub isHet() {
	my $g = shift;
	
	return (substr($g,0,1) eq substr($g,1,1) ? 0 : 1);
}

