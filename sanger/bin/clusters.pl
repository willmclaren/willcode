#!/usr/bin/perl

%args_with_vals = (
	'd' => 1,
	'f' => 1,
	'c' => 1,
	's' => 1,
	'o' => 1,
	'm' => 1,
);

%args = (
	'd' => 5000000,
	'f' => 3,
	'c' => 5,
	's' => 5000000,
	'o' => 'clusters',
	'm' => '/lustre/work1/sanger/wm2/Affy/data/snp.info',
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$usage =<<END;
Usage: perl clusters.pl [options] 

-----------------------------------------------------------

List of options requiring an argument:

	-m	File containing marker information
		(i.e. chromosome, position etc.)
		
Other options:
	-d	Maximum distance between SNPs in cluster [5000000]
	-f	Factor to multiply above distance when merging nearby clusters [3]
	-c	Minimum number of SNPs that define a cluster [5]
	-s	Minimum size of cluster [5000000]
	
	-o	Output file stem [clusters]

END

if($args{'h'} || $args{'-help'}) {
	die $usage;
}


# read map file
open IN, $args{'m'} or die "Could not open map file $args{'m'}\n\n$usage";

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

close IN;




while(<>) {
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	$d{$sample}{$snp} = 1 unless $type eq "HOM";
}

die "No data found in file\n\n$usage" unless scalar keys %d;

$dist = $args{'d'};
$distfactor = $args{'f'};
$minhetsa = $args{'c'} / 2.5;
$minhetsb = $args{'c'};
$minsize = $args{'s'};
$minsizea = $args{'s'} / 2;



open OUT, ">".$args{'o'}.".summary";
open FULL, ">".$args{'o'}.".clusters";

# header lines
print OUT "Sample\tHets\tClusters\tHetsInClusters\t\%InClusters\t\%GenomeCoverage\tMeanDensity\n";
print FULL "Sample\tClusterNum\tChr\tLocation\tFromSNP\tToSNP\tFromBP\tToBP\tHetsInCluster\n";


foreach $sample(keys %d) {
	$c_num = 1;
	@c = ();
	@clusters = ();
	
	$het_count = scalar keys %{$d{$sample}};
	
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
	$total_in_clusters = 0;
	$total_length = 0;
	
	
	# full output
	for $i(0..$#clusters) {
		
		next if $delete{$i};
		
		print FULL
			"$sample\t$c_num\t".$chr{$clusters[$i]->[0]}."\t".
			toMB($pos{$clusters[$i]->[0]})." - ".toMB($pos{$clusters[$i]->[-1]})."MB\t".
			$clusters[$i]->[0]."\t".$clusters[$i]->[-1]."\t".
			($pos{$clusters[$i]->[0]})."\t".($pos{$clusters[$i]->[-1]})."\t".
			(scalar @{$clusters[$i]})."\n";
		
		$total_in_clusters += (scalar @{$clusters[$i]});
		$total_length += $pos{$clusters[$i]->[-1]} - $pos{$clusters[$i]->[0]};
		$c_num++;
	}
	
	# summary headers:
	# 1       2     3         4                5              6         7
	# sample  hets  clusters  num_in_clusters  %_in_clusters  coverage  density
	
	print OUT
		"$sample\t$het_count\t".($c_num - 1)."\t".($total_in_clusters)."\t".
		($het_count ? (100 * $total_in_clusters / $het_count) : 0)."\t".
		(100 * $total_length / 2735383238)."\t".
		($total_length ? ($het_count / ($total_length / 1000000)) : 0)."\n";
}


close OUT;
close FULL;


sub toMB() {
	my $b = shift;
	
	return sprintf("%.2f", $b/1000000);
}