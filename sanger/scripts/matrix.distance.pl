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

# read in the sample order
open IN, shift @ARGV;

$line = 0;
while(<IN>) {
	chomp;
	
	$sample = (split /\s+/, $_)[0];
	
	push @samples, $sample;
	$sampleorder{$sample} = $line;
	$line++;
}

close IN;


$line = 0;

while(<>) {
	chomp;
	
	$_ =~ s/^\s+//g;
	
	@data = split /\s+/, $_;
	
	@{$matrix[$line]} = @data;
	$line++;
}

@list = (scalar keys %l ? keys %l : @samples);

foreach $subject(@list) {
	next unless defined $sampleorder{$subject};
	$x = $sampleorder{$subject};

	%means = ();
	
	foreach $cohort(keys %bycohort) {
		$total = 0;
		$count = 0;
	
		foreach $sample(keys %{$bycohort{$cohort}}) {
			next unless defined $sampleorder{$sample};
			
			$y = $sampleorder{$sample};
			
			$dist = $matrix[$x][$y];
			
			$total += $dist;
			$count++;
		}
		
		$mean = ($count ? $total/$count : 0);
		
		$means{$cohort} = $mean;
	}
	
	foreach $cohort(sort {$means{$a} <=> $means{$b}} keys %means) {
		print "$subject\t$cohort\t$means{$cohort}\n";
	}
}