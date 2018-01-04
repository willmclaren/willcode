#!/usr/bin/perl

%args_with_vals = (
	'g' => 1,
	'o' => 1,
	's' => 1,
	'w' => 1,
);

%args = (
	'o' => 'RHHshare',
	's' => '/nfs/team71/psg/wm2/500k.info',
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# MAP FILE
##########

if(open IN, $args{'s'}) {
	debug("Reading SNP info from $args{'s'}");
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		if(scalar @data == 3) {
			($snp, $chr, $pos) = @data;
		}
		
		elsif(scalar @data == 4) {
			($chr, $snp, $crap, $pos) = @data;
		}
		
		else {
			die "Error in map file: wrong number of columns (".(scalar @data).")\n";
		}
		
		$snps{$chr}{$pos} = $snp;
		$pos{$snp} = $pos;
		$chr{$snp} = $chr;
		
		push @order, $snp;
	}
	
	close IN;
}

else {
	die "Could not open map file $args{'s'}\n";
}


# GENOTYPE DISTRIBUTION FILE
############################

if(open IN, $args{'g'}) {
	debug("Reading genotype counts from $args{'g'}");
	
	while(<IN>) {
		chomp;
		
		@data = split /\t/, $_;
		
		$snp = shift @data;
		
		for $i(0..2) {
			$data[$i+3] =~ tr/ACGT/1234/;
			$counts{$snp}{$data[$i+3]} = ($data[$i] ? $data[$i] : 0);
		}
	}
	
	close IN;
}

else {
	die "Derivation of genotype count file from PED not implemented yet - please specify a genotype count file using -g\n";
}




# READ PED FILE
###############

debug("Reading genotype data from PED file");

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	push @sampleorder, $sample;
	
	for(1..5) { shift @data; }
	
	for $i(0..$#order) {
		die "Not enough columns of data for specified map file (".($i+1)." found)\n" if scalar @data < 2;
		
		$a = shift @data;
		$b = shift @data;
		
		next if ($a.$b eq "00") || ($a.$b eq "NN");
		
		$a =~ tr/ACGT/1234/;
		$b =~ tr/ACGT/1234/;
		
		
		$snp = $order[$i];
		$pos = $pos{$snp};
		$chr = $chr{$snp};
		$gen = $a.$b;
		
		if(!defined $counts{$snp}{$gen}) {
			$gen = $b.$a;
			
			if(!defined $counts{$snp}{$gen}) {
				warn "Genotype $gen for $sample at $snp not found in reference data\n";
				next;
			}
		}
		
		$total = 0;
		$tm = 0;
		
		foreach $ref(keys %{$counts{$snp}}) {
			$c = $counts{$snp}{$ref};
			
			$c-- if $args{'i'} && $ref == $gen;
			
			($ra, $rb) = split //, $ref;
			
			$ma = 0;
			$mb = 0;
			
			$ma++ if $ra eq $a;
			$ma++ if $rb eq $b;
			
			$mb++ if $ra eq $b;
			$mb++ if $rb eq $a;
			
			$m = ($ma > $mb ? $ma : $mb);
			
			$total += (2 * $c);
			$tm += ($m * $c);
		}
		
		$score = ($total > 0 ? $tm / $total : 0);
		
		
		
		#print "$sample\t$snp\t$gen\t$score\n";
		
		$scores{$chr}{$pos} = $score;
		
		#$gen[$#sampleorder][$i] = $a.$b;
	}
	
	
	$width = ($args{'w'} ? $args{'w'} : 0);
	
	foreach $chr(sort {$a <=> $b} keys %scores) {
		@poslist = sort {$a <=> $b} keys %{$scores{$chr}};
		
		for $i(0..$#poslist) {
			$total = 0;
			$count = 0;
		
			for $j(($i - $width > 0 ? $i - $width : 0)..($i + $width <= $#poslist ? $i + $width : $#poslist)) {
				$total += $scores{$chr}{$poslist[$j]};
				$count++;
			}
			
			$smoothed{$chr}{$poslist[$i]} = ($count ? $total / $count : 0);
			
			print "$sample\t$snps{$chr}{$poslist[$i]}\t$chr\t$poslist[$i]\t$smoothed{$chr}{$poslist[$i]}\n";
		}
	}
}



# GET CURRENT DATE AND TIME IN SQL FORMAT
#########################################

sub getTime() {
	my @time = localtime(time());

	# increment the month (Jan = 0)
	$time[4]++;

	# add leading zeroes as required
	for my $i(0..4) {
		$time[$i] = "0".$time[$i] if $time[$i] < 10;
	}

	# put the components together in a string
	my $time =
# 		($time[5] + 1900)."-".
# 		$time[4]."-".
# 		$time[3]." ".
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime;
	my $pid = $$;
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
} 
