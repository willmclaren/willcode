#!/usr/bin/perl


$args{'n'} = 10;
$args{'a'} = "CEU";
$args{'b'} = "YRI";
$args{'g'} = 1;
$args{'t'} = "/lustre/work1/sanger/wm2/HapMap/Phased/all/genotypes_chrCHR_POP_r21_nr_fwd_";


%args_with_vals = (
	'n' => 1,
	'a' => 1,
	'b' => 1,
	'g' => 1,
	't' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$count = $args{'n'};
$popa = $args{'a'};
$popb = $args{'b'};



foreach $num(1..$count) {
	$gen = 1;

	print "\n\n>>> Generating sample no. $num, generation $gen...\n";
	
	while(!$popcounts{$popa}) {	
		$ta = $args{'t'};
		$ta =~ s/CHR/1/g;
		$ta =~ s/POP/$popa/g;
		
		open PIPE, 'grep -c "" '.$ta.'sample.txt |';
		$c = <PIPE>;
		chomp $c;
		$popcounts{$popa} = $c;
		
		print "Population count for $popa : $c\n";
	}
	
	while(!$popcounts{$popb}) {
		$ta = $args{'t'};
		$ta =~ s/CHR/1/g;
		$ta =~ s/POP/$popb/g;
		
		open PIPE, 'grep -c "" '.$ta.'sample.txt |';
		$c = <PIPE>;
		chomp $c;
		$popcounts{$popb} = $c;
		
		print "Population count for $popb : $c\n";
	}

	$i1 = int(rand($popcounts{$popa}));
	$i2 = int(rand($popcounts{$popb}));
	
	$used{$i1} = 1;
	
	while($used{$i2}) {
		$i2 = int(rand($popcounts{$popb}));
	}
	
	$used{$i2} = 1;
	
	

	foreach $chrom(1..22) {
		$ta = $args{'t'};
		$ta =~ s/CHR/$chrom/g;
		$ta =~ s/POP/$popa/g;
		
		$tb = $args{'t'};
		$tb =~ s/CHR/$chrom/g;
		$tb =~ s/POP/$popb/g;
		
		
		print "\n> Generating chromsome $chrom\n";
		system("cross.hapmap.pl -i1 $i1 -i2 $i2 -l1 ".$ta."legend_all -p1 ".$ta."phased_all -s1 ".$ta."sample.txt -l2 ".$tb."legend_all -p2 ".$tb."phased_all -s2 ".$tb."sample.txt -o $popa\.$popb\.$num\.f$gen\.chr$chrom");
		
		# convert to genotype file
		system("hapmap2geno.pl -l $popa\.$popb\.$num\.f$gen\.chr$chrom\.legend -p $popa\.$popb\.$num\.f$gen\.chr$chrom\.phased -s $popa\.$popb\.$num\.f$gen\.chr$chrom\.sample -o $popa\.$popb\.$num\.f$gen\.chr$chrom");
	}
	
	# concatenate genotype files
	system("cat $popa\.$popb\.$num\.f$gen\.chr\*\.g | sort -k 2 > $popa\.$popb\.$num\.f$gen\.g");
	
	$gen++;
	
	while($gen <= $args{'g'}) {
		$prev_gen = $gen - 1;
	
		print "\n\n>>> Breeding sample $num with population $popa, generation $gen\n";
		
		$i1 = int(rand($popcounts{$popa}));
		
		while($used{$i1}) {
			$i1 = int(rand($popcounts{$popa}));
		}
		
		$used{$i1} = 1;
		
		foreach $chrom(1..22) {
			$ta = $args{'t'};
			$ta =~ s/CHR/$chrom/g;
			$ta =~ s/POP/$popa/g;
			
			print "\n> Generating chromsome $chrom\n";
			system("cross.hapmap.pl -i1 $i1 -i2 1 -l1 ".$ta."legend_all -p1 ".$ta."phased_all -s1 ".$ta."sample.txt -l2 $popa\.$popb\.$num\.f$prev_gen\.chr$chrom\.legend -p2 $popa\.$popb\.$num\.f$prev_gen\.chr$chrom\.phased -s2 $popa\.$popb\.$num\.f$prev_gen\.chr$chrom\.sample -o $popa\.$popb\.$num\.f$gen\.chr$chrom -r ../../Recombination/rates/genetic_map_chr$chrom\.txt -r2");
			
			# convert to genotype file
			system("hapmap2geno.pl -l $popa\.$popb\.$num\.f$gen\.chr$chrom\.legend -p $popa\.$popb\.$num\.f$gen\.chr$chrom\.phased -s $popa\.$popb\.$num\.f$gen\.chr$chrom\.sample -o $popa\.$popb\.$num\.f$gen\.chr$chrom");
		}
		
		# concatenate genotype files
		system("cat $popa\.$popb\.$num\.f$gen\.chr\*\.g | sort -k 2 > $popa\.$popb\.$num\.f$gen\.g");
		
		$gen++;
	}
	
	
	# remove intermediate files
	system("rm $popa\.$popb\.$num\.f\*\.chr\*");
}
