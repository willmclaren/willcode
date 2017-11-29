#!/usr/bin/perl

$head = <>;
chomp $head;
@heads = split /\t/, $head;
shift @heads;
shift @heads;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$s = shift @data;
	$trans{$s} = shift @data;
	
	push @samples, $s;
	
	foreach $snp(@heads) {
		$a = shift @data;
		$a = join "", sort {$a <=> $b} (split //, $a);
	
		$data{$s}{$snp} = $a;
		$seen{$snp}{$a} = 1 if $data{$s}{$snp};
	}
}

foreach $snp(@heads) {
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

print "$head\n";

foreach $s(@samples) {
	print $s."\t".$trans{$s};
	
	foreach $snp(@heads) {
		print "\t".$conv{$snp}{$data{$s}{$snp}};
		
		#print "\t".($data{$s}{$snp} ? ($conv{$snp}{$data{$s}{$snp}}) + 1 : "-");
	}
	
	print "\n";
}


sub isHom() {
	my $a = shift;
	
	return 1 if substr($a,0,1) eq substr($a,1,1);
}