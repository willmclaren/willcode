#!/usr/bin/perl

$args{'s'} = qq/\/lustre\/work1\/sanger\/wm2\/HapMap\/MDS\/wrong.HapMap.cohorts/;

%args_with_vals = (
	's' => 1,
	'l' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

unless(open IN, $args{'s'}) {
	print "WARNING: population label file $args{'s'} not found\n";
	print "Attempting to read from file \"HapMap.cohorts\" ... ";
	$args{'s'} = "HapMap.cohorts";
	
	if(open IN, $args{'s'}) {
		print "success";
		
		close IN;
	}
	else {
		die "failed - aborting";
	}
	
	print "\n";
}


open IN, $args{'s'};
while(<IN>) {
	chomp;
	
	($sample, $cohort) = split /\s+/, $_;
	
	$cohort{$sample} = $cohort;
	$bycohort{$cohort}{$sample} = 1;
}
close $args{'s'};

if($args{'l'}) {
	@list = split /\,/, $args{'l'};
	foreach $l(@list) {
		$l{$l} = 1;
	}
}

$header = <>;
chomp $header;
$header =~ s/^\s+//g;
@headers = split /\s+/, $header;

while(<>) {
	chomp;
	s/^\s+//g;
	
	@data = split /\s+/, $_;
	
	foreach $header(@headers) {
		$a = shift @data;
		
		if($header eq 'FID') {
			$sample = $a;
		}
		
		elsif($header =~ /^C\d+/) {
			$data{$sample}{$header} = $a;
			$used{$header} = 1;
		}
	}
}


#foreach $sample($args{'l'} ? @list : keys %data) {
foreach $sample(keys %data) {
	#%dist = ();

	foreach $cohort(keys %bycohort) {
		$cohort_total = 0;
		$cohort_counts = 0;
	
		foreach $b(keys %{$bycohort{$cohort}}) {
			$total = 0;
		
			next unless $data{$b};
			next if $sample eq $b;
		
			foreach $h(keys %used) {
				$total += (($data{$sample}{$h} - $data{$b}{$h}) * ($data{$sample}{$h} - $data{$b}{$h}));
			}
			
			$dist = sqrt($total);
			
			$cohort_total += $dist;
			$cohort_counts++;
		}
		
		$cohort_mean = ($cohort_counts ? $cohort_total/$cohort_counts : 0);
			
		#print "Distance between $sample and $cohort is $dist\n";
		
		$dist{$sample}{$cohort} = $cohort_mean;
	}
}

foreach $cohort(keys %bycohort) {
	@a = ();
	$total = 0;
	
	# calculate the mean
	foreach $s(keys %{$bycohort{$cohort}}) {
		next unless $data{$s};
		
		#print "Cheese $s $cohort $dist{$s}{$cohort}\n";
		
		push @a, $dist{$s}{$cohort};
		$total += $dist{$s}{$cohort};
	}
	
	$mean = ((scalar @a) ? ($total / (scalar @a)) : 0);
	
	# calculate the variance
	$total = 0;
	foreach $point(@a) {
		$total += (($point - $mean)*($point - $mean));
	}
	
	$var{$cohort} = ((scalar @a) ? ($total / (scalar @a)) : 0);
	$mean{$cohort} = $mean;
	
	#print "Cohort $cohort $mean $var{$cohort} ".(scalar @a)."\n";
}


foreach $sample($args{'l'} ? @list : keys %data) {
	foreach $cohort(sort {$dist{$sample}{$a} <=> $dist{$sample}{$b}} keys %{$dist{$sample}}) {
		print "$sample\t$cohort\t$dist{$sample}{$cohort}\t$mean{$cohort}\t$var{$cohort}";
		
		$z = ($var{$cohort} ? ($dist{$sample}{$cohort} - $mean{$cohort}) / $var{$cohort} : 0);
		
		print "\t$z\n";
	}
}