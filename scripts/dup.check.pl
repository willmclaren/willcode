#!/usr/bin/perl


%args_with_vals = (
	'o' => 1,
);

# process arguments from command line
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	push @snps, $data[1];
}

close IN;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	for(1..5) {
		shift @data;
	}
	
	push @samples, $sample;
	
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
	
		$g{$sample}{$snp} = join "", sort {$a <=> $b} ($a,$b);
	}
}

for $i(0..$#samples) {
	for $j(0..$#samples) {
		next if $i == $j;
	
		$na = 0;
		$nb = 0;
		$t = 0;
		$m = 0;
		
		foreach $snp(@snps) {
			if($g{$samples[$i]}{$snp} > 0) {
				if($g{$samples[$j]}{$snp} > 0) {
					$m++ if $g{$samples[$i]}{$snp} eq $g{$samples[$j]}{$snp};
					$t++;
				}
				
				else {
					$nb++;
				}
			}
			
			else {
				$na++;
			}
		}
		
		$n{$samples[$i]} = $na;
		$n{$samples[$j]} = $nb;
		
		$m{$samples[$i]}{$samples[$j]} = ($t ? (100 * ($m/$t)) : 0);
		$m{$samples[$j]}{$samples[$i]} = ($t ? (100 * ($m/$t)) : 0);
		$t{$samples[$j]}{$samples[$i]} = $t;
	}
}

open OUT, ">".($args{'o'} ? $args{'o'}.'.' : "dupcheck")."full";

foreach $s(keys %m) {
	$best = (sort {$m{$s}{$a} <=> $m{$s}{$b}} keys %{$m{$s}})[-1];
	$best_score = $m{$s}{$best};
	
	@best = ();
	foreach $t(keys %{$m{$s}}) {
		push @best, $t if $m{$s}{$t} == $best_score;
		
		print OUT "$s\t$t\t$m{$s}{$t}\t$t{$s}{$t}\n";
	}
	
	#print "For $s, found ".(scalar @best)." matches with $best_score\n";
	
	$best = (sort {$t{$s}{$a} <=> $t{$s}{$b}} @best)[-1];
	
	$best_n = $best;
	if($n{$s} == $n{$best_n}) {
		$best_n = (sort ($s, $best_n))[-1];
	}
	
	else {
		$best_n = $s if $n{$s} < $n{$best_n};
	}
	
	print "$s\t$best\t$best_score\t".($t{$s}{$best} ? $t{$s}{$best} : ($t{$best}{$s} ? $t{$best}{$s} : 0))."\t$best_n\t".($best_n eq $best ? $s : $best)."\n";
}

close OUT;