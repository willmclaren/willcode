#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use Statistics::Basic::Correlation;

use Statistics::Basic::Mean;
use Statistics::Basic::Median;
use Statistics::Basic::Variance;


# ARGUMENTS
%args_with_vals = (
	'p' => 1,
	'r' => 1,
);

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

#print "buggery";

# read file containing p-values
open IN, $args{'p'} or die ($args{'p'} ? "Could not open p-value file $args{'p'}\n" : "p-value file not specified (use -p)\n");

while(<IN>) {

	chomp;
	
	$_ =~ s/^\s+//g;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 2) {
		$p{$data[0]} = -(log($data[1])/log(10));
	}
	
	else {
		next unless /ALLELIC/;
		$p{$data[0]} = -(log($data[-2])/log(10));
	}
	
 	#print "$data[0]\t$p{$data[0]}\n";
}

close IN;


# read file containing r2 values (from HapMap)
open IN, $args{'r'} or die ($args{'r'} ? "Could not open r2 file $args{'r'}\n" : "r2 file not specified (use -r)\n");

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	next unless $p{$data[3]} || $p{$data[4]};
	
	if($p{$data[3]}) {
		$r{$data[4]}{$data[3]} = $data[6];
	}
	
	else {
		$r{$data[3]}{$data[4]} = $data[6];
	}
}

close IN;


# iterate through each ungenotyped SNP
foreach $un(keys %r) {
	next if $p{$un};
	
	@p = ();
	@r = ();
	
	$max = 0;
	$min = 1;
	$maxp = 0;
	$minp = 5000;
	
	# put the p and r2 values for each corresponding genotyped SNP into arrays
	foreach $ge(keys %{$r{$un}}) {
		next unless $p{$ge};
		
		push @p, $p{$ge};
		push @r, $r{$un}{$ge};
		
		$max = $r[-1] if $r[-1] > $max;
		$min = $r[-1] if $r[-1] < $min;
		
		$maxp = $p[-1] if $p[-1] > $maxp;
		$minp = $p[-1] if $p[-1] < $minp;
	}
	
	# skip this SNP if there were no genotyped SNPs in any sort of LD with it
	next unless $max > 0;
	
	# calculate the correlation
	$c = new Statistics::Basic::Correlation(\@p, \@r);
	$corr = $c->query;
	
	
	# r2 value distribution stats
	
	# calculate the mean r2
	$m = new Statistics::Basic::Mean(\@r);
	$mean = $m->query;
	
	# calculate the median r2
	$m = new Statistics::Basic::Median(\@r);
	$med = $m->query;
	
	# calculate the variance for r2
	$m = new Statistics::Basic::Variance(\@r);
	$var = $m->query;
	
	
	# p-value distribution stats
	
	# calculate the mean r2
	$m = new Statistics::Basic::Mean(\@p);
	$meanp = $m->query;
	
	# calculate the median r2
	$m = new Statistics::Basic::Median(\@p);
	$medp = $m->query;
	
	# calculate the variance for r2
	$m = new Statistics::Basic::Variance(\@p);
	$varp = $m->query;
	
	# print output line for this SNP
	print "$un\t$corr\t$mean\t$med\t$var\t$min\t$max\t$meanp\t$medp\t$varp\t$minp\t$maxp\t".(scalar @p)."\n";
	
# 	foreach $snp(@list) {
# 		print "\t$snp\t$r{$linked}{$snp}";
# 	}
# 	
# 	print "\n";
}