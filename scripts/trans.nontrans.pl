#!/usr/bin/perl

%args_with_vals = (
	't' => 1,
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
	
	@data = split /\s+/, $_;
	
	$fam = shift @data;
	$id = shift @data;
	
	$dad = shift @data;
	$mum = shift @data;
	
	$sex = shift @data;
	$aff = shift @data;
	
# 	print "$mum\t$dad\t$aff\n";
	
	if($mum && $dad && ($aff == 2)) {
		$aff{$fam}{$id} = 1;
	}
	
	$fam{$id} = $fam;
	$dad{$id} = $dad;
	$mum{$id} = $mum;
	
	$fams{$fam} = 1;
}

close IN;


while(<>) {
	chomp;
	
	($id, $chrom, $seq) = split /\t|\_/, $_;
	
	$fam = substr($id, 0, 6);
	
	if($seq =~ /\s+/) {
		@{$chroms{$fam}{$id}{$chrom}} = split /\s+/, $seq;
	}
	
	else {
		@{$chroms{$fam}{$id}{$chrom}} = split //, $seq;
	}
}

open OUT, ">debug";


$thresh = ($args{'t'} ? $args{'t'} : 0.95);

foreach $fam(keys %fams) {
# foreach $fam(qw/549213/) {

	foreach $aff(keys %{$aff{$fam}}) {
# 	foreach $aff(qw/54921305/) {
		$mum = $mum{$aff};
		$dad = $dad{$aff};
		
		next unless $mum && $dad && ($fam{$mum} eq $fam) && ($fam{$dad} eq $fam);
		
		$kid_a = join " ", @{$chroms{$fam}{$aff}{'A'}};
		$kid_b = join " ", @{$chroms{$fam}{$aff}{'B'}};
		
		$dad_a = join " ", @{$chroms{$fam}{$dad}{'A'}};
		$dad_b = join " ", @{$chroms{$fam}{$dad}{'B'}};
		
		$mum_a = join " ", @{$chroms{$fam}{$mum}{'A'}};
		$mum_b = join " ", @{$chroms{$fam}{$mum}{'B'}};
		
# 		print substr($kid_a, 0, 10)."\n";
# 		print substr($dad_a, 0, 10)."\n";
		print OUT "\n";
		
		%comp = ();
		%best = ();
		
		$kidkid = compare(\@{$chroms{$fam}{$aff}{'A'}}, \@{$chroms{$fam}{$aff}{'B'}});
		
		foreach $p($dad, $mum) {
			foreach $kid_chrom(qw/A B/) {
				foreach $p_chrom(qw/A B/) {
					$comp{$p}{$kid_chrom."_".$p_chrom} = compare(\@{$chroms{$fam}{$aff}{$kid_chrom}}, \@{$chroms{$fam}{$p}{$p_chrom}});
					
					print OUT "$fam\t$aff\_$kid_chrom\t$p\_$p_chrom\t".$comp{$p}{$kid_chrom."_".$p_chrom}."\n";
				}
			}
			
			$best = (sort {$comp{$p}{$a} <=> $comp{$p}{$b}} keys %{$comp{$p}})[-1];
			$score = (sort {$a <=> $b} values %{$comp{$p}})[-1];
			
			print OUT "$p $best\n";
			$fullbest{$p} = $best;
			$best{$p} = (split /\_/, $best)[-1];
			$score{$p} = $score;
		}
		
		# if both parents best match is the same chrom
		if((split /\_/, $fullbest{$dad})[0] eq (split /\_/, $fullbest{$mum})[0]) {
			if(compare(\@{$chroms{$fam}{$aff}{'A'}}, \@{$chroms{$fam}{$aff}{'B'}}) == 1) {
				if($score{$dad} >= $thresh) {
					trans($dad."_".$best{$dad});
					print OUT "$dad\_$best{$dad} transmitted\n";
				}
				
				if($score{$mum} >= $thresh) {
					trans($mum."_".$best{$mum});
					print OUT "$mum\_$best{$mum} transmitted\n"
				}
			}
			
			elsif(compare(\@{$chroms{$fam}{$dad}{'A'}}, \@{$chroms{$fam}{$dad}{'B'}}) == 1) {
				if(compare(\@{$chroms{$fam}{$mum}{'A'}}, \@{$chroms{$fam}{$mum}{'B'}}) < 1) {
					if($score{$mum} >= $thresh) {
						trans($mum."_".$best{$mum});
						print OUT "$mum\_$best{$mum} transmitted\n"
					}
				}
			}
			
			elsif(compare(\@{$chroms{$fam}{$mum}{'A'}}, \@{$chroms{$fam}{$mum}{'B'}}) == 1) {
				if(compare(\@{$chroms{$fam}{$dad}{'A'}}, \@{$chroms{$fam}{$dad}{'B'}}) < 1) {
					if($score{$dad} >= $thresh) {
						trans($dad."_".$best{$dad});
						print OUT "$dad\_$best{$dad} transmitted\n";
					}
				}
			}
		}
		
		else {
			if($score{$dad} >= $thresh) {
				trans($dad."_".$best{$dad});
				print OUT "$dad\_$best{$dad} transmitted\n";
			}
			
			if($score{$mum} >= $thresh) {
				trans($mum."_".$best{$mum});
				print OUT "$mum\_$best{$mum} transmitted\n"
			}
		}
	}
}

# foreach $fam(keys %fams) {
# 	foreach $aff(keys %{$aff{$fam}}) {
# # 	foreach $aff(qw/54921305/) {
# 		$mum = $mum{$aff};
# 		$dad = $dad{$aff};
# 		
# 		if($trans{"$dad\_A"} + $trans{"$dad\_B"} >= 1) {
# 			foreach $c(keys %{$chroms{$fam}{$dad}}) {
# 				print "$dad\_$c\t".($trans{"$dad\_$c"} ? $trans{"$dad\_$c"} : 0)."\n";
# 			}
# 		}
# 		
# 		if($trans{"$mum\_A"} + $trans{"$mum\_B"} >= 1) {
# 			foreach $c(keys %{$chroms{$fam}{$mum}}) {
# 				print "$mum\_$c\t".($trans{"$mum\_$c"} ? $trans{"$mum\_$c"} : 0)."\n";
# 			}
# 		}
# 		
# 		last;
# 	}
# }

# foreach $chrom(sort keys %trans) {
# 	print "$chrom\t$trans{$chrom}\n";
# }

sub compare() { 
	my ($a, $b) = @_;
	
# 	print "Comparing ".substr($a, 0, 10)." with ".substr($b, 0, 10)."\n";
	
# 	my @a = @{$a};
# 	my @b = @{$b};
	
	my $max = (scalar @$a > scalar @$b ? scalar @$b : scalar @$a);
	
	my $match = 0;
	my $total = 0;
	
	foreach my $i(0..($max-1)) {
		next if ($a->[$i] eq '-') || ($b->[$i] eq '-');
		$match++ if $a->[$i] eq $b->[$i];
		$total++;
	}
	
	return ($total ? $match/$total : $total);
}


sub trans() {
	my ($id, $c) = split /\_/, shift;
	
	print "$id\_$c\t1\n$id\_".($c eq 'A' ? 'B' : 'A')."\t0\n";
}
	