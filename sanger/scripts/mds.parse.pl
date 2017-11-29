#!/usr/bin/perl

$head = <>;
chomp $head;
@header = split /\t/, $head;

while(<>) {
	s/^ +//g;
	s/ +/\t/g;
	
	chomp;
	
	@data = split /\t/, $_;
	$sample = $data[0];
	$c1 = $data[3];
	$c2 = $data[4];
	$set = $data[-1];
	
	@{$data{$set}{$sample}} = ($c1, $c2);
}

foreach $set('CEU','CHB','YRI') {
	@samples = keys %{$data{$set}};
	
	$x_max = -999999;
	$x_min = 999999;
	$y_max = -999999;
	$y_min = 999999;
	
	# calculate pair-wise sample distances
	for $i(0..($#samples)) {
		
		$x_max = $data{$set}{$samples[$i]}[0] if $data{$set}{$samples[$i]}[0] > $x_max;
		$x_min = $data{$set}{$samples[$i]}[0] if $data{$set}{$samples[$i]}[0] < $x_min;
		$y_max = $data{$set}{$samples[$i]}[1] if $data{$set}{$samples[$i]}[1] > $y_max;
		$y_min = $data{$set}{$samples[$i]}[1] if $data{$set}{$samples[$i]}[1] < $y_min;
		
		
		last if $i == $#samples;
	
		for $j(($i+1)..$#samples) {
			$dist = dist($data{$set}{$samples[$i]}, $data{$set}{$samples[$j]});
			
			$dist{$i}{$j} = $dist;
		}
	}
	
	# get centre of cluster
	@{$centre{$set}} = (($x_max + $x_min)/2, ($y_max + $y_min)/2);
	
	$bounds{$set}{'xmin'} = $x_min;
	$bounds{$set}{'xmax'} = $x_max;
	$bounds{$set}{'ymin'} = $y_min;
	$bounds{$set}{'ymax'} = $y_max;
	
	
	#print "Centre of $set is at @{$centre{$set}}\n";
}

foreach $set('CEU','CHB','YRI') {
	$total_dist = 0;
	
	foreach $setb('CEU','CHB','YRI') {
		next if $setb eq $set;
		$total_dist += dist($centre{$set}, $centre{$setb});
	}
	
	$mean_oth{$set} = $total_dist / 2;
	
	#print "Mean for $set is $mean_oth{$set}\n";
}


foreach $sample(keys %{$data{'0'}}) {
	$total_dist = 0;
	
	foreach $set('CEU','CHB','YRI') {
		$x = $data{'0'}{$sample}->[0];
		$y = $data{'0'}{$sample}->[1];
		
		if(
			($x > $bounds{$set}{'xmin'}) &&
			($x < $bounds{$set}{'xmax'}) &&
			($y > $bounds{$set}{'ymin'}) &&
			($y < $bounds{$set}{'ymax'})
		) {
			$prop{$set} = 1;
		}
		
		else {
	
			$dist = dist($centre{$set}, $data{'0'}{$sample});
		
			if($dist >= $mean_oth{$set}) {
				$prop{$set} = 0;
			}
			
			else {
				$prop{$set} = 1 - ($dist / $mean_oth{$set});
			}
		}
			
		$total_dist += $prop{$set};
	}
	
	$first = 1;
	
	foreach $set('CEU','CHB','YRI') {
		$ratio = ($prop{$set}/$total_dist);
		print ($first ? "" : "\t");
		print $ratio;
		$first = 0;
	}
	print "\n";
}


sub dist() {
	($a, $b) = @_;
	
	return sqrt((($a->[0] - $b->[0])*($a->[0] - $b->[0])) + (($a->[1] - $b->[1])*($a->[1] - $b->[1])));
}