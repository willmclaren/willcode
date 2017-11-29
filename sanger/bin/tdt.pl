#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl/';
use Statistics::Distributions qw (chisqrprob);

$args{'o'} = 'mytdt';

%args_with_vals = (
	's' => 1,
	'o' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# process 's' argument
if($args{'s'}) {
	@s = split /\,/, $args{'s'};
}


# read in the file containing the order of the markers
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if(scalar @data == 4) {
		($chr, $snp, $crap, $pos) = @data;
	}
	
	elsif(scalar @data == 3) {
		($snp, $chr, $pos) = @data;
	}
	
	push @snps, $snp;
}

close IN;

# define the first columns of the ped file
@cols = qw/fam id dad mum sex aff/;

# read the ped file from STDIN
while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$id = $data[1];
	$fam = $data[0];
	
	# read the sample info into a hash
	foreach $col(@cols) {
		$data{$id}{$col} = shift @data;
	}
	
	# record this sample as a member of its family
	$fam{$fam}{$id} = 1;
	
	# now record the marker data
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
		
		$data{$id}{$snp} = "$a $b";
	}
}


# open a debug file if required
open OUT, ">".$args{'o'}."\.debug" if $args{'d'};


# flag parents who are homozygous for chosen SNP (if specified)
if($args{'s'}) {
	debug("Flagging parents homozygous at locus/loci $args{'s'}");

	foreach $fam(keys %fam) {
		
		foreach $kid(keys %{$fam{$fam}}) {
			
			# check affection status and presence of parents
			# we're only interested in parents of affected kids
			next unless $data{$kid}{'aff'} == 2;
			next unless $data{$data{$kid}{'dad'}};
			next unless $data{$data{$kid}{'mum'}};
			
			# assign parents
			$dad = $data{$kid}{'dad'};
			$mum = $data{$kid}{'mum'};
			
			$hom = 0;
			
			foreach $snp(@s) {
			
				# get paternal alleles
				($a, $b) = split /\s+/, $data{$dad}{$snp};
				
				# increment if they are genotyped and homozygous
				if($a && $b && ($a == $b)) {
					$hom++;
				}
			}
			
			if($hom == scalar @s) {
				$use{$dad} = 1;
				
				if($args{'a'}) {
					foreach $snp(@s) {
						$hom{$dad}{$snp} = (split /\s+/, $data{$dad}{$snp})[0];
					}
				}
			}
			
			$hom = 0;
			
			foreach $snp(@s) {
			
				# get maternal alleles
				($a, $b) = split /\s+/, $data{$mum}{$snp};
				
				# increment if they are genotyped and homozygous
				if($a && $b && ($a == $b)) {
					$hom++;
				}
			}
			
			
			if($hom == scalar @s) {
				$use{$mum} = 1;
				
				if($args{'a'}) {
					foreach $snp(@s) {
						$hom{$mum}{$snp} = (split /\s+/, $data{$mum}{$snp})[0];
					}
				}
			}
			
			# just counters for the number of samples looked at
			$count{$dad} = 1;
			$count{$mum} = 1;
		}
	}
	
	debug("Flagged ".(scalar keys %use)." parents of ".(scalar keys %count));
}




# now go through each marker in the ped file
foreach $snp(@snps) {
	
	# skip this marker if it is the one that has been used to flag parents
	next if $args{'s'} && ($snp eq $args{'s'});
	
	# go through each family
	foreach $fam(keys %fam) {
		
		debug("\n>>>>\tAnalysing family $fam - ".(scalar keys %{$fam{$fam}})." members");		
		
		# iterate through each affected kid
		foreach $kid(keys %{$fam{$fam}}) {
			
			# check affection status and presence of parents
			next unless $data{$kid}{'aff'} == 2;
			next unless $data{$data{$kid}{'dad'}};
			next unless $data{$data{$kid}{'mum'}};
			
			# assign parents
			$dad = $data{$kid}{'dad'};
			$mum = $data{$kid}{'mum'};
			
			# skip if we are using flagged parents and neither mum nor dad are flagged
			if($args{'s'}) {
				next unless $use{$mum} || $use{$dad};
			}
				
			# get the parental alleles
			($dad_a, $dad_b) = split / /, $data{$dad}{$snp};
			($mum_a, $mum_b) = split / /, $data{$mum}{$snp};
			
			# skip this trio if both parents are homs (no useful information)
			if(($dad_a eq $dad_b) && ($mum_a eq $mum_b)) {
				debug("Both parents are homs - no analysis possible ($dad_a|$dad_b $mum_a|$mum_b)");
				next;
			}
			
			# skip this trio if any missing data (no useful information)
			if(
				($dad_a == 0) || ($dad_b == 0) || ($mum_a == 0) || ($mum_b == 0)
			) {
				debug("Missing genotypes - no analysis possible");
				next;
			}
			
			
			debug("Checking affected kid $kid");
			
			# check that the kid has genotypes at this locus
			($kid_a, $kid_b) = split / /, $data{$kid}{$snp};
			if(($kid_a == 0) || ($kid_b == 0)) {
				debug("Missing genotypes");
				next;
			}
			
			
			debug("Dad: $dad_a\|$dad_b Mum: $mum_a\|$mum_b Kid: $kid_a\|$kid_b");
			
			# dad is a het
			if($dad_a ne $dad_b) {
				
				# mum is het
				if($mum_a ne $mum_b) {
				
					debug("Dad is het, mum is het");
					
					# is kid hom
					if($kid_a eq $kid_b) {
						debug("Kid is hom");
						
						# ($dad_a eq $kid_b ? 't' : 'n') <--- this switcher is used when incrementing counts
						# We know kid_b comes from dad, but is it dad_a or dad_b?
						# So if dad_a equals kid_b then dad_a is transmitted, dad_b isn't
						if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
							$counts{$snp}{$dad_a}{($dad_a eq $kid_b ? 't' : 'n')}++;
							$counts{$snp}{$dad_b}{($dad_b eq $kid_b ? 't' : 'n')}++;
							debug("Dad: ".($dad_a eq $kid_b ? $dad_a : $dad_b)." transmitted, ".($dad_b eq $kid_b ? $dad_a : $dad_b)." not");
							
							if($args{'a'}) {
								@ref_id = ();
							
								foreach $ref(@s) {
									push @ref_id, $hom{$dad}{$ref};
								}
								
								$ref_id = join "\t", @ref_id;
								
								$countsbyhom{$snp}{$dad_a}{$ref_id}{($dad_a eq $kid_b ? 't' : 'n')}++;
								$countsbyhom{$snp}{$dad_b}{$ref_id}{($dad_b eq $kid_b ? 't' : 'n')}++;
							}
						}
						
						if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
							$counts{$snp}{$mum_a}{($mum_a eq $kid_b ? 't' : 'n')}++;
							$counts{$snp}{$mum_b}{($mum_b eq $kid_b ? 't' : 'n')}++;
							debug("Mum: ".($mum_a eq $kid_b ? $mum_a : $mum_b)." transmitted, ".($mum_b eq $kid_b ? $mum_a : $mum_b)." not");
							
							if($args{'a'}) {
								@ref_id = ();
							
								foreach $ref(@s) {
									push @ref_id, $hom{$mum}{$ref};
								}
								
								$ref_id = join "\t", @ref_id;
								
								$countsbyhom{$snp}{$mum_a}{$ref_id}{($mum_a eq $kid_b ? 't' : 'n')}++;
								$countsbyhom{$snp}{$mum_b}{$ref_id}{($mum_b eq $kid_b ? 't' : 'n')}++;
							}
						}
					}
					
					else {
						debug("Kid is het");
						
						if(($data{$dad}{$snp} =~ /$kid_a/) && ($data{$mum}{$snp} =~ /$kid_a/)) {
							if($data{$dad}{$snp} =~ /$kid_b/) {
								# kid_b is from dad
								debug("kid_b is from dad (both have kid_a)");
							
								if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
									$counts{$snp}{$dad_a}{($dad_a eq $kid_b ? 't' : 'n')}++;
									$counts{$snp}{$dad_b}{($dad_b eq $kid_b ? 't' : 'n')}++;
									debug("Dad: ".($dad_a eq $kid_b ? $dad_a : $dad_b)." transmitted, ".($dad_b eq $kid_b ? $dad_a : $dad_b)." not");
									
									if($args{'a'}) {
										@ref_id = ();
							
										foreach $ref(@s) {
											push @ref_id, $hom{$dad}{$ref};
										}
										
										$ref_id = join "\t", @ref_id;
										
										$countsbyhom{$snp}{$dad_a}{$ref_id}{($dad_a eq $kid_b ? 't' : 'n')}++;
										$countsbyhom{$snp}{$dad_b}{$ref_id}{($dad_b eq $kid_b ? 't' : 'n')}++;
									}
								}
								
								if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
									$counts{$snp}{$mum_a}{($mum_a eq $kid_a ? 't' : 'n')}++;
									$counts{$snp}{$mum_b}{($mum_b eq $kid_a ? 't' : 'n')}++;
									debug("Mum: ".($mum_a eq $kid_a ? $mum_a : $mum_b)." transmitted, ".($mum_b eq $kid_a ? $mum_a : $mum_b)." not");
									
									if($args{'a'}) {
										@ref_id = ();
							
										foreach $ref(@s) {
											push @ref_id, $hom{$mum}{$ref};
										}
										
										$ref_id = join "\t", @ref_id;
										
										$countsbyhom{$snp}{$mum_a}{$ref_id}{($mum_a eq $kid_a ? 't' : 'n')}++;
										$countsbyhom{$snp}{$mum_b}{$ref_id}{($mum_b eq $kid_a ? 't' : 'n')}++;
									}
								}
							}
							
							else {
								# kid_b is from mum
								debug("kid_b is from mum (both have kid_a)");
								
								if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
									$counts{$snp}{$dad_a}{($dad_a eq $kid_a ? 't' : 'n')}++;
									$counts{$snp}{$dad_b}{($dad_b eq $kid_a ? 't' : 'n')}++;
									debug("Dad: ".($dad_a eq $kid_a ? $dad_a : $dad_b)." transmitted, ".($dad_b eq $kid_a ? $dad_a : $dad_b)." not");
									
									if($args{'a'}) {
										@ref_id = ();
							
										foreach $ref(@s) {
											push @ref_id, $hom{$dad}{$ref};
										}
										
										$ref_id = join "\t", @ref_id;
										
										$countsbyhom{$snp}{$dad_a}{$ref_id}{($dad_a eq $kid_a ? 't' : 'n')}++;
										$countsbyhom{$snp}{$dad_b}{$ref_id}{($dad_b eq $kid_a ? 't' : 'n')}++;
									}
								}
								
								if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
									$counts{$snp}{$mum_a}{($mum_a eq $kid_b ? 't' : 'n')}++;
									$counts{$snp}{$mum_b}{($mum_b eq $kid_b ? 't' : 'n')}++;
									debug("Mum: ".($mum_a eq $kid_b ? $mum_a : $mum_b)." transmitted, ".($mum_b eq $kid_b ? $mum_a : $mum_b)." not");
									
									if($args{'a'}) {
										@ref_id = ();
							
										foreach $ref(@s) {
											push @ref_id, $hom{$mum}{$ref};
										}
										
										$ref_id = join "\t", @ref_id;
										
										$countsbyhom{$snp}{$mum_a}{$ref_id}{($mum_a eq $kid_b ? 't' : 'n')}++;
										$countsbyhom{$snp}{$mum_b}{$ref_id}{($mum_b eq $kid_b ? 't' : 'n')}++;
									}
								}
							}
						}
						
						elsif($data{$dad}{$snp} =~ /$kid_a/) {
							# kid_a is from dad
							debug("kid_a is from dad");
							
							if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
								$counts{$snp}{$dad_a}{($dad_a eq $kid_a ? 't' : 'n')}++;
								$counts{$snp}{$dad_b}{($dad_b eq $kid_a ? 't' : 'n')}++;
								debug("Dad: ".($dad_a eq $kid_a ? $dad_a : $dad_b)." transmitted, ".($dad_b eq $kid_a ? $dad_a : $dad_b)." not");
								
								if($args{'a'}) {
									@ref_id = ();
							
									foreach $ref(@s) {
										push @ref_id, $hom{$dad}{$ref};
									}
									
									$ref_id = join "\t", @ref_id;
									
									$countsbyhom{$snp}{$dad_a}{$ref_id}{($dad_a eq $kid_a ? 't' : 'n')}++;
									$countsbyhom{$snp}{$dad_b}{$ref_id}{($dad_b eq $kid_a ? 't' : 'n')}++;
								}
							}
							
							if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
								$counts{$snp}{$mum_a}{($mum_a eq $kid_b ? 't' : 'n')}++;
								$counts{$snp}{$mum_b}{($mum_b eq $kid_b ? 't' : 'n')}++;
								debug("Mum: ".($mum_a eq $kid_b ? $mum_a : $mum_b)." transmitted, ".($mum_b eq $kid_b ? $mum_a : $mum_b)." not");
								
								if($args{'a'}) {
									@ref_id = ();
							
									foreach $ref(@s) {
										push @ref_id, $hom{$mum}{$ref};
									}
									
									$ref_id = join "\t", @ref_id;
									
									$countsbyhom{$snp}{$mum_a}{$ref_id}{($mum_a eq $kid_b ? 't' : 'n')}++;
									$countsbyhom{$snp}{$mum_b}{$ref_id}{($mum_b eq $kid_b ? 't' : 'n')}++;
								}
							}
						}
						
						else {
							# kid_a is from mum
							debug("kid_a is from mum");
							
							if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
								$counts{$snp}{$dad_a}{($dad_a eq $kid_b ? 't' : 'n')}++;
								$counts{$snp}{$dad_b}{($dad_b eq $kid_b ? 't' : 'n')}++;
								debug("Dad: ".($dad_a eq $kid_b ? $dad_a : $dad_b)." transmitted, ".($dad_b eq $kid_b ? $dad_a : $dad_b)." not");
								
								if($args{'a'}) {
									@ref_id = ();
							
									foreach $ref(@s) {
										push @ref_id, $hom{$dad}{$ref};
									}
									
									$ref_id = join "\t", @ref_id;
									
									$countsbyhom{$snp}{$dad_a}{$ref_id}{($dad_a eq $kid_b ? 't' : 'n')}++;
									$countsbyhom{$snp}{$dad_b}{$ref_id}{($dad_b eq $kid_b ? 't' : 'n')}++;
								}
							}
							
							if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
								$counts{$snp}{$mum_a}{($mum_a eq $kid_a ? 't' : 'n')}++;
								$counts{$snp}{$mum_b}{($mum_b eq $kid_a ? 't' : 'n')}++;
								debug("Mum: ".($mum_a eq $kid_a ? $mum_a : $mum_b)." transmitted, ".($mum_b eq $kid_a ? $mum_a : $mum_b)." not");
								
								if($args{'a'}) {
									@ref_id = ();
							
									foreach $ref(@s) {
										push @ref_id, $hom{$mum}{$ref};
									}
									
									$ref_id = join "\t", @ref_id;
									
									$countsbyhom{$snp}{$mum_a}{$ref_id}{($mum_a eq $kid_a ? 't' : 'n')}++;
									$countsbyhom{$snp}{$mum_b}{$ref_id}{($mum_b eq $kid_a ? 't' : 'n')}++;
								}
							}
						}
					}
				}
				
				
				# mum is hom
				else {
					
					debug("Dad is het, mum is hom");
					
					# which allele did the kid get from mum?
					if($mum_a eq $kid_a) {
						$mat = $kid_a;
						$pat = $kid_b;
					}
					else {
						$mat = $kid_b;
						$pat = $kid_a;
					}
					
					# so we know that one of dad's alleles was transmitted - which one?
					if(($args{'s'} && $use{$dad}) || (!$args{'s'})) {
						if($dad_a eq $pat) {
							# dad_a was transmitted
							$counts{$snp}{$dad_b}{'n'}++;
							$counts{$snp}{$dad_a}{'t'}++;
							
							debug("Dad: $dad_a transmitted, $dad_b not");
							
							if($args{'a'}) {
								@ref_id = ();
							
								foreach $ref(@s) {
									push @ref_id, $hom{$dad}{$ref};
								}
								
								$ref_id = join "\t", @ref_id;
								
								$countsbyhom{$snp}{$dad_b}{$ref_id}{'n'}++;
								$countsbyhom{$snp}{$dad_a}{$ref_id}{'t'}++;
							}
						}
						else {
							# dad_b was transmitted
							$counts{$snp}{$dad_a}{'n'}++;
							$counts{$snp}{$dad_b}{'t'}++;
							
							debug("Dad: $dad_b transmitted, $dad_a not");
							
							if($args{'a'}) {
								@ref_id = ();
							
								foreach $ref(@s) {
									push @ref_id, $hom{$dad}{$ref};
								}
								
								$ref_id = join "\t", @ref_id;
								
								$countsbyhom{$snp}{$dad_a}{$ref_id}{'n'}++;
								$countsbyhom{$snp}{$dad_b}{$ref_id}{'t'}++;
							}
						}
					}
				}
			}
			
			# dad is hom and implicitly mum is het
			else {
			
				debug("Dad is hom, mum is het");
				
				# which allele did the kid get from dad?
				if($dad_a eq $kid_a) {
					$pat = $kid_a;
					$mat = $kid_b;
				}
				else {
					$pat = $kid_b;
					$mat = $kid_a;
				}
				
				debug("Pat: $pat\tMat: $mat");
				
				# so we know that one of mum's alleles was transmitted - which one?
				if(($args{'s'} && $use{$mum}) || (!$args{'s'})) {
					if($mum_a eq $mat) {
						# mum_a was transmitted
						$counts{$snp}{$mum_b}{'n'}++;
						$counts{$snp}{$mum_a}{'t'}++;
							
						debug("Mum: $mum_a transmitted, $mum_b not");
						
						if($args{'a'}) {
							@ref_id = ();
							
							foreach $ref(@s) {
								push @ref_id, $hom{$mum}{$ref};
							}
							
							$ref_id = join "\t", @ref_id;
								
							$countsbyhom{$snp}{$mum_b}{$ref_id}{'n'}++;
							$countsbyhom{$snp}{$mum_a}{$ref_id}{'t'}++;
						}
					}
					else {
						# mum_b was transmitted
						$counts{$snp}{$mum_a}{'n'}++;
						$counts{$snp}{$mum_b}{'t'}++;
							
						debug("Mum: $mum_b transmitted, $mum_a not");
						
						if($args{'a'}) {
							@ref_id = ();
							
							foreach $ref(@s) {
								push @ref_id, $hom{$mum}{$ref};
							}
							
							$ref_id = join "\t", @ref_id;
							
							$countsbyhom{$snp}{$mum_a}{$ref_id}{'n'}++;
							$countsbyhom{$snp}{$mum_b}{$ref_id}{'t'}++;
						}
					}
				}
			}
		}
	}
}

open FULL, ">".$args{'o'}."_full.tdt" if $args{'a'};
open OUT, ">".$args{'o'}.".tdt";

# now generate the output for each marker analysed
foreach $snp(@snps) {
	next unless $counts{$snp};
	
	# iterate through each allele
	foreach $allele(sort {$a <=> $b} keys %{$counts{$snp}}) {
		$t = $counts{$snp}{$allele}{'t'};
		$n = $counts{$snp}{$allele}{'n'};
		
		# caculate the chi square statistic
		$chi = (($t-$n)*($t-$n))/($t+$n);
		
		print OUT
			"$snp\t$allele\t".
			($t ? $t : 0)."\t".
			($n ? $n : 0)."\t".
			
			# chisqprob() returns the p-value associated with the chi square statistic at the given D.F.
			$chi.
			"\t".chisqrprob(1, $chi).
			"\n";
		
		# bi-allelic markers don't need output for both alleles
		# since the second allele just has the same counts inverted
		last if scalar keys %{$counts{$snp}} == 2;
	}
	
	# if we are generating full "by allele" output
	if($args{'a'}) {
		foreach $allele(sort {$a <=> $b} keys %{$countsbyhom{$snp}}) {
			foreach $ref(sort keys %{$countsbyhom{$snp}{$allele}}) {
			
				$t = $countsbyhom{$snp}{$allele}{$ref}{'t'};
				$n = $countsbyhom{$snp}{$allele}{$ref}{'n'};
				
				# caculate the chi square statistic
				$chi = (($t-$n)*($t-$n))/($t+$n);
				
				print FULL
					"$snp\t$allele\t$ref\t".
					($t ? $t : 0)."\t".
					($n ? $n : 0)."\t".
					
					# chisqprob() returns the p-value associated with the chi square statistic at the given D.F.
					$chi.
					"\t".chisqrprob(1, $chi).
					"\n";
			}
				
			# bi-allelic markers don't need output for both alleles
			# since the second allele just has the same counts inverted
			last if scalar keys %{$counts{$snp}} == 2;
		}
	}
}

close FULL if $args{'a'};
close OUT;


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime();
	
	print OUT $time." - ".$text.($text =~ /\n$/ ? "" : "\n") if $args{'d'};
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
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}