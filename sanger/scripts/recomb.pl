#!/usr/bin/perl

%args_with_vals = (
	'r' => 1,
	'l' => 1,
	's' => 1,
	'p' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}



# read in SNP legend file
die "No SNP legend file specified\n" unless $args{'l'};

print "Reading SNP legend file\n";

open IN, $args{'l'} or die "Could not open file $args{'l'}\n";
while(<IN>) {
	chomp;
	next if /^rs$/;
	next if /position/;
	($snp, $pos, $a, $b) = split /\s+/, $_;
	$seen_pos{$pos} = 1;
	
	$snps{$pos} = $snp;
	
	$legend{$snp}{0} = $a;
	$legend{$snp}{1} = $b;
}
close IN;



# read in recombination info file
die "No recombination info file specified\n" unless $args{'r'};

print "Reading ecombination info file\n";

open IN, $args{'r'} or die "Could not open file $args{'r'}\n";
while(<IN>) {
	chomp;
	next if /position/;
	
	($pos, $rate, $dist) = split /\s+/, $_;
	
	next unless $seen_pos{$pos};
	
	$recomb{$pos} = $dist;
}
close IN;


@pos_list = sort {$a <=> $b} keys %snps;

for(1..1000) {
	foreach $pos(@pos_list) {
		next unless $recomb{$pos};
	
		if($last_pos) {
			$dist = $recomb{$pos} - $last_dist;
			
			$num = rand(100);
			
			if($num < $dist) {
				#print "Recombination between $snps{$last_pos} \($last_pos\) and $snps{$pos} \($pos\) : $dist $num $recomb{$pos} $last_dist\n";
				
				$rec++;
			}
			
	# 		else {
	# 			print "$dist $num $recomb{$pos} $last_dist\n";
	# 		}
		}
		
		$last_pos = $pos;
		$last_dist = $recomb{$pos};
		#print "Poo $pos $last_pos $last_dist\n";
	}
}

print "$rec\n";