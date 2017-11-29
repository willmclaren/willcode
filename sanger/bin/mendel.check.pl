#!/usr/bin/perl

if(scalar @ARGV > 1) {

	# LOAD MAP FILE
	open IN, shift @ARGV;
	
	debug("Loading map file");
	
	$marker = 1;
	
	while(<IN>) {
		next if /^Snp_/;
		
		chomp;
		
		@data = split /\s+/, $_;
		
		$order{$marker} = $data[0];
		
		$snps{$data[0]}{'chr'} = $data[1];
		$snps{$data[0]}{'pos'} = $data[2];
		
		$marker++;
	}
	
	close IN;
}


debug("Reading ped file");

# NOW LOAD IN THE DATA
while(<>) {
	chomp;
	
	@line = split /\s+/, $_;
	
	$id = $line[1];
	$info{$id}{'sex'} = $line[4];
	$info{$id}{'aff'} = $line[5];
	
	$ped{$id}{'dadid'} = $line[2];
	$ped{$id}{'momid'} = $line[3];
	$ped{$id}{'pedid'} = $line[0];	
	
	for(1..6) {
		shift @line;
	}
	
	$marker = 1;
	
	while(@line) {
		$a = shift @line;
		$b = shift @line;
		
		$geno = $a.$b;
				
		$data{$id}{$marker} = $geno;
		
		$marker++;
	}
	
	$num_markers = $marker - 1;
}


debug("Constructing families");

# SORT PEDIGREES INTO FAMILIES
foreach $id(keys %ped) {
	if($ped{$id}{'dadid'} > 0 && $ped{$id}{'momid'} > 0) {
		$fam{$ped{$id}{'pedid'}}{'kids'}{$id} = 1;
		
		$rel{$kid}{'dad'} = $ped{$id}{'dadid'};
		$rel{$kid}{'mom'} = $ped{$id}{'momid'};
		
		$fam{$ped{$id}{'pedid'}}{'parents'}{$ped{$id}{'momid'}} = 1;# unless scalar @{$fam{$ped{$id}{'pedid'}}{'parents'}} >= 2;
		$fam{$ped{$id}{'pedid'}}{'parents'}{$ped{$id}{'dadid'}} = 1;# unless scalar @{$fam{$ped{$id}{'pedid'}}{'parents'}} >= 2;
	}
}


debug("Analysing families");

# ITERATE THROUGH FAMILIES
foreach $family(sort {$a <=> $b} keys %fam) {
	
	@parents = keys %{$fam{$family}{'parents'}};
	@kids = keys %{$fam{$family}{'kids'}};
	
	debug("Analysing pedigree $family (".(scalar @parents + scalar @kids)." individuals)");
	
	foreach $marker(1..$num_markers) {
		
		# MAKE POSSIBLE CHILD GENOTYPES
		%poss = ();
		
		%present = ();
		
		foreach $parent_a(@parents) {
			foreach $parent_b(@parents) {
				next if $parent_a eq $parent_b;
				next if $info{$parent_a}{'sex'} eq $info{$parent_b}{'sex'};
				
				$a = $data{$parent_a}{$marker};
				$b = $data{$parent_b}{$marker};
				
				$combo = join "", (sort {$a <=> $b} ($parent_a, $parent_b));
				
				foreach $all_a(split //, $a) {
					foreach $all_b(split //, $b) {
						push @{$poss{$combo}}, join "", (sort {$a <=> $b} ($all_a, $all_b));
						
						$present{$all_a} = 1;
						$present{$all_b} = 1;
					}
				}
			}
		}
		
		# CHECK EACH CHILD
		foreach $kid(@kids) {
			$geno = join "", (sort {$a <=> $b} (split //, $data{$kid}{$marker}));
			
			next if $geno eq '00';
			
			# CHECK FOR HALF-TYPING
			if($geno =~ /0/) {
				print "ERROR(2): $family, $kid, $marker, $order{$marker}, $data{$kid}{$marker}\n";
				next;
			}
			
			# CHECK FOR CONSISTENCY
			$father = $rel{$kid}{'dad'};
			$mother = $rel{$kid}{'mom'};
			
			$combo = join "", (sort {$a <=> $b} ($father, $mother));
			
			$match = 0;
			
			if($data{$father}{$marker} == 0 && $data{$mother}{$marker} == 0) {
				$match = 1;
			}
			
			
			else {
				foreach $poss_geno(@{$poss{$combo}}) {
					if($geno =~ /$poss_geno/) {
						$match = 1;
					}
				}
			}
			
			if(!$match) {
				print "ERROR(1): $family, $marker, $order{$marker}, $father: $data{$father}{$marker}, $mother: $data{$mother}{$marker}, $kid: $data{$kid}{$marker}\n";
			}
			
			foreach $all(split //, $geno) {
				$present{$all} = 1 unless $all == 0;
			}
		}
		
		# CHECK NUMBER OF ALLELES IN SIBSHIP
		if(scalar keys %present > 4) {
			print "ERROR(3): $family, ".(join '/', (keys %present));
			print "\n";
		}
		
	}
}





# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime();
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
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