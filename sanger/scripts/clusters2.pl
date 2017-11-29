#!/usr/bin/perl

%args_with_vals = (
	'd' => 1,
	'f' => 1,
	'c' => 1,
	's' => 1,
	'o' => 1,
);

%args = (
	'd' => 5000000,
	'f' => 3,
	'c' => 5,
	's' => 5000000,
	'o' => 'clusters'
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}



open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chr, $pos) = split /\t/, $_;
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

while(<>) {
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	$d{$sample}{$snp} = 1;
}

$dist = $args{'d'};
$distfactor = $args{'f'};
$minhetsa = $args{'c'} / 2.5;
$minhetsb = $args{'c'};
$minsize = $args{'s'};
$minsizea = $args{'s'} / 2;

foreach $sample(keys %d) {
	$c_num = 1;
	@c = ();
	@clusters = ();
	
	foreach $snp(sort {$chr{$a} <=> $chr{$b} || $pos{$a} <=> $pos{$b}} keys %{$d{$sample}}) {
		$chr = $chr{$snp};
		$pos = $pos{$snp};
		
		if(($chr == $prev_chr) && ($pos - $prev_pos < $dist)) {
			push @c, $snp;
		}
		
		elsif(@c) {
			if(($pos{$c[-1]} - $pos{$c[0]} > $minsizea) && (scalar @c >= $minhetsa)) {
				my @d = @c;
				push @clusters, \@d;
				#print "$sample\t$c_num\t$prev_chr\t$c[0]\t$c[-1]\t$pos{$c[0]}\t$pos{$c[-1]}\t".(scalar @c)."\n";
				$c_num++;
			}
			
			@c = ();
		}
		
		else {
			push @c, $snp;
		}
		
		$prev_pos = $pos;
		$prev_chr = $chr;
	}
	
	if(@c) {
		if(($pos{$c[-1]} - $pos{$c[0]} > $minsizea) && (scalar @c >= $minhetsa)) {
			my @d = @c;
			push @clusters, \@d;
			#print "$sample\t$c_num\t$prev_chr\t$c[0]\t$c[-1]\t$pos{$c[0]}\t$pos{$c[-1]}\t".(scalar @c)."\n";
			$c_num++;
		}
	}
	
	%delete = ();
	
	$prev_seen = scalar @clusters;
	$seen = 0;
	
	# see if we can merge any clusters
	if(scalar @clusters >= 2) {
		$round = 1;
	
		while($seen != $prev_seen) {
			
			#print "> Round $round\n";
		
			$prev_seen = ($seen ? $seen : scalar @clusters);
			$p = 0;
			$seen = 1;
			
			for $i(1..$#clusters) {
				next if $delete{$i};
				$seen++;
				
				if($chr{$clusters[$i]->[0]} eq $chr{$clusters[$p]->[0]} && $pos{$clusters[$i]->[0]} - $pos{$clusters[$p]->[-1]} < ($distfactor * $dist)) {
					#print "Merging clusters ".($p+1)." and ".($i+1)."\n";
					
					push @{$clusters[$p]}, @{$clusters[$i]};
					$delete{$i} = 1;
					$seen--;
				}
				
				else {
					$p = $i;
				}
			}
			
			if($round == 1) {
				for $i(0..$#clusters) {
					next if $delete{$i};
					
					if(scalar @{$clusters[$i]} < $minhetsb) {
						$delete{$i} = 1;
					}
					
					if($pos{$clusters[$i]->[-1]} - $pos{$clusters[$i]->[0]} < $minsize) {
						$delete{$i} = 1;
					}
				}
			}
			
			$round++;
		}
	}
	
	$c_num = 1;
	
	for $i(0..$#clusters) {
# 		if($i - 1 >= 0 && $clusters[$i]->[-1] eq $clusters[$i-1]->[-1]) {
# 			next;
# 		}
		
		next if $delete{$i};
		
		print
			"$sample\t$c_num\t".$chr{$clusters[$i]->[0]}."\t".
			toMB($pos{$clusters[$i]->[0]})." - ".toMB($pos{$clusters[$i]->[-1]})."MB\t".
			$clusters[$i]->[0]."\t".$clusters[$i]->[-1]."\t".
			($pos{$clusters[$i]->[0]})."\t".($pos{$clusters[$i]->[-1]})."\t".
			(scalar @{$clusters[$i]})."\n";
		
		$c_num++;
	}
}


sub toMB() {
	my $b = shift;
	
	return sprintf("%.2f", $b/1000000);
}