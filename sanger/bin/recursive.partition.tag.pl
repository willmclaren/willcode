#!/usr/bin/perl

%args_with_vals = (
	's' => 1,
	'o' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

if(open IN, $args{'s'}) {
	while(<IN>) {
		chomp;
		push @snps, (split /\s+/, $_)[0];
	}
	
	close IN;
}

else {
	$head = <>;
	chomp $head;
	
	@snps = split /\s+/, $head;
	shift @snps;
}

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	$sample = shift @data;
	
	foreach $snp(@snps) {
		$a = shift @data;
		$data{$sample}{$snp} = $a;
		
		$obs{$snp}{$a} = 1;
	}
	
	push @samples, $sample;
}


@list = qw/
	hla_a
	hla_cw
	hla_b
	hla_drb1
	hla_dqb1
	hla_dqa1
	hla_dpa1
	hla_dpb1
/;

foreach $target(@list) {
	foreach $obs(keys %{$obs{$target}}) {
		%counts = ();
		%ratio = ();
		
		foreach $sample(@samples) {
			$t = ($data{$sample}{$target} eq $obs ? 1 : 0);
		
			foreach $snp(@snps) {
				next if $snp eq $target;
				next if scalar keys %{$obs{$snp}} == 1;
				
				$counts{$snp}{$t}{$data{$sample}{$snp}}++ unless $data{$sample}{$snp} eq '-';
			}
		}
		
		foreach $snp(@snps) {
			next if $snp eq $target;
			next if scalar keys %{$obs{$snp}} != 2;
			
			#print "Bob";
			
			($a, $b) = keys %{$obs{$snp}};
			
			$c1 = $counts{$snp}{0}{$a} + $counts{$snp}{1}{$b};
			$c2 = $counts{$snp}{1}{$a} + $counts{$snp}{0}{$b};
			
			if($c1 > $c2) {
				$ratio = $c1 / ($c2 + $c1);
			}
			
			else {
				$ratio = $c2 / ($c1 + $c2);
			}
			
			$ratio{$snp} = $ratio;
			
			$out{$snp} = "$counts{$snp}{0}{$a}\t$counts{$snp}{0}{$b}\t$counts{$snp}{1}{$a}\t$counts{$snp}{1}{$b}"
		}
		
		$best = (sort {$ratio{$a} <=> $ratio{$b}} keys %ratio)[-1];
		

		print "$target\t$obs\t$best\t$ratio{$best}\t$out{$best}\n";
	}
}