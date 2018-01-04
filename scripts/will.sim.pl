#!/usr/bin/perl


# open marker counts
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($count, $num) = split /\t/, $_;
	
	$cont{$count} = $num;
}

close IN;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($sample, $count) = split /\t/, $_;
	
	$cuts{$count}++;
	
	$total_samples++;
}

close IN;

#####################################################################
#####################################################################
#####################################################################
#####################################################################
#####################################################################


# SIMULATION
############

$sim_number = 1000;
$num_cuts = 20;

my $m = 0;
my %SNPs;
my $Total_SNPs;

foreach my $num(sort {$a <=> $b} keys %cont) {
	$SNPs[$num] = $cont{$num};
	$Total_SNPs += $SNPs[$num];
	$m++;
}


#$total_samples = scalar keys %seen_samples;


#$sim_number = ($args{'sims'} ? $args{'sims'} : 1000);


	my @counts = sort {$b <=> $a} keys %cuts;
	
	my $rare_counts, $samples_with_rare_counts, $hshkey, $cutpoint_number;
	my %cutpoint_or_more_extreme, %cutpoint_to_less_extreme_than_next_cutpoint;
	
	for (my $i=0;$i<=$num_cuts;$i++) {
		$rare_counts = $counts[$i];

		if ($rare_counts==0) {last;}

		$samples_with_rare_counts = $cuts{$counts[$i]};

		# in the next statement, a hash key is created which is defined by the number of counts to the left of the decimal of the key
		# and number of samples displaying such counts to the right of the decimal of the key

		$hshkey=$rare_counts."."."0" x (length($total_samples)-length($samples_with_rare_counts)).$samples_with_rare_counts;

		$cutpoint_or_more_extreme{$hshkey} = 0;

		$cutpoint_to_less_extreme_than_next_cutpoint{$hshkey} = 0;

		$cutpoint_number = $i;			# keep tally of number of entered cutpoints 
	}

	@sorted_cutpoint_keys = sort {$a <=> $b} (keys %cutpoint_or_more_extreme);   # sort cutpoint hash keys for use below



($sec, $min, $hour, $day) = (localtime)[0,1,2,3];   # get time and date



$outfile1 = 
	($out_stem ? $out_stem."_" : "")."permut_samp".$total_samples.
	"_sim".$sim_number."_SNPs_".$SNPs[1]."_".$SNPs[$m]."_dt_".$sec."_".$min."_".$day.".txt"; 



open (PERMUT, ">$outfile1");


print PERMUT "Total Samples: ", $total_samples, "\t Number of simulations: ", $sim_number, "\n";

print PERMUT "SNP rare hets or homs distribution:", "\n";


for (my $i=1; $i<=$m; $i++) {
	print PERMUT $SNPs[$i], " SNPs, each contributing ", $i, " counts \n";
}




if ($cutyesno==1) {
	print PERMUT "\n Cutpoints investigated:", "\n\n";
	
	foreach $sorted_cutpoint_keys (@sorted_cutpoint_keys) {
		print PERMUT $sorted_cutpoint_keys, "\n";
	}
}


print PERMUT "Numbers (a)left and (b)right of each decimal point are: \n";
print PERMUT "  (a)number of rare het or hom counts displayed by the sample\n";
print PERMUT "  (b)total number of samples displaying this number of counts in a single simulation \n\n";
print PERMUT "Integer adjacent to decimal number is number of times observed among the ", $sim_number, " total simulations\n\n";

# This statement specifies the number of simulations ($sim_number)
for ($sim_count=1; $sim_count<=$sim_number;$sim_count++) {

	for ($cc=0; $cc<=$total_samples-1;$cc++) {
		$counts_for_sample[$cc]=0;   #initialize the array that will contain randomly selected hits - one array element for each sample
	}

	# The nested for loops below randomly select $i array elements for each SNP where $i is the number of rare counts contributed by a SNP
	# Each time an array element is randomly selected, it is incremented once to signify that the SNP has contributed 1 count to the sample
	# represented by the corresponding array element 

	for ($i=1; $i<=$m;$i++) {
		for ($j=1;$j<=$SNPs[$i];$j++) {
			for ($k=1;$k<=$i;$k++) {
	
				randomselect:
	
				$random_index[$k]=int(rand($total_samples));
				
				# This for loop with corresponding if statement prevents the same sample 
				# (i.e. same array index)from being selected twice for the same SNP
				for ($duplicate_test=$k-1;$duplicate_test>=1;$duplicate_test--) {
					if ($random_index[$k]==$random_index[$duplicate_test]) {goto randomselect;}  
				}

				$counts_for_sample[$random_index[$k]]=$counts_for_sample[$random_index[$k]]+1;
			}
		}
	}
	
	@ascending_counts_for_sample = sort {$a <=> $b} @counts_for_sample;
	
	$hits_counter = 0;
	
	$counts_this_sample = $ascending_counts_for_sample[0];
	
	if ($sim_count == ($screenupdate + 1)) {
		print "Doing simulation ", $sim_count, "\n";
		$screenupdate += 50;
	}

# note:  $#listname is the last array element in @listname
for(my $i=0; $i<=$#ascending_counts_for_sample; $i++) {

	if ($ascending_counts_for_sample[$i]==$counts_this_sample) {
		$hits_counter++;
	}

	else {
		# a hash key is created (or referenced if already exist) which is defined by the number of counts to left  
		# the decimal of the key and number of samples displaying such counts to the right of the decimal of the key
		$hshkey=$counts_this_sample . "." . "0" x (length($total_samples)-length($hits_counter)) . $hits_counter;		
		
		# hash which sums - across all simulations - the number of times observed for a particular 
		# number of rare hets or homs in a particular number of samples
		$sim_tabulation{$hshkey}=$sim_tabulation{$hshkey}+1;    	


		for(my $k=0; $k<=$cutpoint_number; $k++) {
			if (  
				(int($hshkey) >= int($sorted_cutpoint_keys[$k])) &&
				((substr($hshkey,index($hshkey,".") + 1)  + ($#ascending_counts_for_sample - $i) ) >=  substr($sorted_cutpoint_keys[$k],index($sorted_cutpoint_keys[$k],".")+1)) &&
				($last_incremented_simulation_extreme[$k]<$sim_count)
			) {
				$cutpoint_or_more_extreme{$sorted_cutpoint_keys[$k]}=$cutpoint_or_more_extreme{$sorted_cutpoint_keys[$k]}+1;
				$last_incremented_simulation_extreme[$k]=$sim_count;
			}
		}
	

		for(my $k=0; $k<=$cutpoint_number-1; $k++) {

			if (($hshkey >= $sorted_cutpoint_keys[$k]) && ($hshkey < $sorted_cutpoint_keys[$k+1]) &&  ($last_incremented_simulation_less_ext[$k]<$sim_count))

				{

				$cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys[$k]}=$cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys[$k]}+1;

				$last_incremented_simulation_less_ext[$k]=$sim_count;

				last;

				}

			}	
				
		$counts_this_sample=$ascending_counts_for_sample[$i];

		$hits_counter=1;

		}


	}

	$hshkey=$counts_this_sample . "." . "0" x (length($total_samples)-length($hits_counter)) . $hits_counter;

	$sim_tabulation{$hshkey}=$sim_tabulation{$hshkey}+1;  


	for (my $k=0; $k<=$cutpoint_number; $k++)

		{

			if (  

				(int($hshkey) >= int($sorted_cutpoint_keys[$k]))  

				&& (  ( substr($hshkey,index($hshkey,".")+1)  ) >=  substr($sorted_cutpoint_keys[$k],index($sorted_cutpoint_keys[$k],".")+1) )

				&& ($last_incremented_simulation_extreme[$k]<$sim_count)   

				)

			

			{

			$cutpoint_or_more_extreme{$sorted_cutpoint_keys[$k]}=$cutpoint_or_more_extreme{$sorted_cutpoint_keys[$k]}+1;

			$last_incremented_simulation_extreme[$k]=$sim_count;

			}

		}
	

	for (my $k=0; $k<=$cutpoint_number-1; $k++)

		{

		if (($hshkey >= $sorted_cutpoint_keys[$k]) && ($hshkey < $sorted_cutpoint_keys[$k+1]) &&  ($last_incremented_simulation_less_ext[$k]<$sim_count))

			{

			$cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys[$k]}=$cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys[$k]}+1;

			$last_incremented_simulation_less_ext[$k]=$sim_count;

			last;

			}

		}	
	
}



# The $sim_tabulation hash is sorted by applying ideas on pp. 166-167 of the Perl Cookbook as well as the idea implemented above that two keys separated by a decimal can be treated as a single key

												
@sim_tab_sort_key = sort {$a <=> $b} (keys %sim_tabulation);				

foreach $sim_tab_sort_key(@sim_tab_sort_key)

	{
	print PERMUT $sim_tab_sort_key, "\t", $sim_tabulation{$sim_tab_sort_key}, "\t probab=";
	printf PERMUT "%.8f \n ", $sim_tabulation{$sim_tab_sort_key}/$sim_number;
	}

print PERMUT "\n\n Distribution of counts at or more extreme than cutpoints\n\n";

foreach $sorted_cutpoint_keys (@sorted_cutpoint_keys)

	{
	print PERMUT $sorted_cutpoint_keys, "\t", $cutpoint_or_more_extreme{$sorted_cutpoint_keys}, "\t probab=";
	printf PERMUT "%.8f \n \n", $cutpoint_or_more_extreme{$sorted_cutpoint_keys}/$sim_number;
	}

print PERMUT "\n\n\n";

print PERMUT "\n\n Distribution of counts at or less extreme than the next cutpoint\n\n";

foreach $sorted_cutpoint_keys (@sorted_cutpoint_keys)

	{
	print PERMUT $sorted_cutpoint_keys, "\t", $cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys}, "\t probab=";
	printf PERMUT "%.8f \n \n", $cutpoint_to_less_extreme_than_next_cutpoint{$sorted_cutpoint_keys}/$sim_number;
	}

close PERMUT;
