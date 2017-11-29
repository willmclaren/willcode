#!/usr/bin/perl

start:                  # start label for goto statement


print "Program to simulate clustering of rare het or hom counts in individual samples based on the following parameters: \n";
print "  Total number of samples \n";
print "  For the total samples, the number of SNPs that contribute 1, 2, 3,... n counts \n";


print "The user also enters the number of rounds of simulation to be conducted (100, 1000, etc.) in order to estimate p-values \n\n";



$m=0;

for ($i=1;$i<=100;$i++)

	{

	print "enter number of SNPs with ", $i, " counts:  ";

	$SNPs[$i]=<STDIN>;

	chop($SNPs[$i]);

	$Total_SNPs=$Total_SNPs+$SNPs[$i];

	if ($SNPs[$i]==0)  {print "End of entry for distribution of SNPs giving rare counts \n \n";  last;}

	$m=$m+1;		#  m number of different kinds of SNP - kind defined by number of counts
	}

print "Enter total number of samples: ";

$total_samples=<STDIN>;

chop($total_samples);


print "\n", "Enter number of simulations to conduct (e.g. 100, 1000, 10000): ";

$sim_number=<STDIN>;

chop($sim_number);

print "\n", "Do you want to enter distribution cutpoints,", "\n", " i.e., number of counts by number of samples displaying that numberof counts(1=yes, 0=no)? ";

$cutyesno=<STDIN>;

chop ($cutyesno);

if ($cutyesno==1)

	{
	print "\n Enter cutpoints \n";
 
	for ($i=0;$i<=20;$i++)
		{
		print "Enter integer counts displayed by sample (1 to n) - or just hit return to terminate cutpoint entry: ";

		$rare_counts=<STDIN>;

		chop($rare_counts);

		if ($rare_counts==0) {last;}

		print "Enter number of samples (1 to n) displaying ", $rare_counts, " counts to further define the cutpoint: ";

		$samples_with_rare_counts=<STDIN>;

		chop($samples_with_rare_counts);

		# in the next statement, a hash key is created which is defined by the number of counts to the left of the decimal of the key
		# and number of samples displaying such counts to the right of the decimal of the key

		$hshkey=$rare_counts . "." . "0" x (length($total_samples)-length($samples_with_rare_counts)) . $samples_with_rare_counts;

		$cutpoint_or_more_extreme{$hshkey}=0;

		$cutpoint_to_less_extreme_than_next_cutpoint{$hshkey}=0;

		$cutpoint_number=$i;			# keep tally of number of entered cutpoints 

		}

	@sorted_cutpoint_keys = sort {$a <=> $b} (keys %cutpoint_or_more_extreme);   # sort cutpoint hash keys for use below

	}
		


print "\n", "Hit return to continue; to reenter data, type any character followed by return";

$reenter=<STDIN>;

chop($reenter);

if ($reenter ne "") {goto start;}


($sec, $min, $hour, $day) = (localtime)[0,1,2,3];   # get time and date



$outfile1="permut_samp" . $total_samples . "_sim" . $sim_number . "_SNPs_" . $SNPs[1] . "_" . $SNPs[$m] . "_dt_" . $sec . "_" . $min . "_" . $day . ".txt"; 



open (PERMUT, ">$outfile1");


print PERMUT "Total Samples: ", $total_samples, "\t Number of simulations: ", $sim_number, "\n";

print PERMUT "SNP rare hets or homs distribution:", "\n";


for (my $i=1; $i<=$m; $i++)

	{

	print PERMUT $SNPs[$i], " SNPs, each contributing ", $i, " counts \n";

	}




if ($cutyesno==1)

{
print PERMUT "\n Cutpoints investigated:", "\n\n";


foreach $sorted_cutpoint_keys (@sorted_cutpoint_keys) 

	{

	print PERMUT $sorted_cutpoint_keys, "\n";
	
	}
}



print PERMUT "Numbers (a)left and (b)right of each decimal point are: \n";
print PERMUT "  (a)number of rare het or hom counts displayed by the sample\n";
print PERMUT "  (b)total number of samples displaying this number of counts in a single simulation \n\n";
print PERMUT "Integer adjacent to decimal number is number of times observed among the ", $sim_number, " total simulations\n\n";
 



for ($sim_count=1; $sim_count<=$sim_number;$sim_count++)   # This statement specifies the number of simulations ($sim_number)


{

for ($cc=0; $cc<=$total_samples-1;$cc++)

	{

	$counts_for_sample[$cc]=0;   #initialize the array that will contain randomly selected hits - one array element for each sample

	}

# The nested for loops below randomly select $i array elements for each SNP where $i is the number of rare counts contributed by a SNP
# Each time an array element is randomly selected, it is incremented once to signify that the SNP has contributed 1 count to the sample
# represented by the corresponding array element 

for ($i=1; $i<=$m;$i++)

	{

	for ($j=1;$j<=$SNPs[$i];$j++)

		{

		for ($k=1;$k<=$i;$k++)

			{

			randomselect:

				$random_index[$k]=int(rand($total_samples));

				for ($duplicate_test=$k-1;$duplicate_test>=1;$duplicate_test--)			# This for loop with corresponding if statement prevents the same sample 
																				# (i.e. same array index)from being selected twice for the same SNP
					{

					if ($random_index[$k]==$random_index[$duplicate_test]) {goto randomselect;}  

					}

				$counts_for_sample[$random_index[$k]]=$counts_for_sample[$random_index[$k]]+1;


			}

		}

	}


@ascending_counts_for_sample=sort {$a <=> $b} @counts_for_sample;


$hits_counter=0;

$counts_this_sample=$ascending_counts_for_sample[0];

 
if ($sim_count==$screenupdate+1)

	{print "\n Doing simulation ", $sim_count, "\n";
	 $screenupdate=$screenupdate+50;}


for (my $i=0; $i<=$#ascending_counts_for_sample; $i++)    # note:  $#listname is the last array element in @listname

	{

	if ($ascending_counts_for_sample[$i]==$counts_this_sample)

		{$hits_counter=$hits_counter+1;}

	else
		{

		$hshkey=$counts_this_sample . "." . "0" x (length($total_samples)-length($hits_counter)) . $hits_counter;		# a hash key is created (or referenced if already exist) which is defined by the number of counts to left  
																					# the decimal of the key and number of samples displaying such counts to the right of the decimal of the key
		

		$sim_tabulation{$hshkey}=$sim_tabulation{$hshkey}+1;    	# hash which sums - across all simulations - the number of times observed for a particular 
											  	# number of rare hets or homs in a particular number of samples


		for (my $k=0; $k<=$cutpoint_number; $k++)

			{


			if (  

				(int($hshkey) >= int($sorted_cutpoint_keys[$k]))  

				&& (  ( substr($hshkey,index($hshkey,".")+1)  + ($#ascending_counts_for_sample - $i) ) >=  substr($sorted_cutpoint_keys[$k],index($sorted_cutpoint_keys[$k],".")+1) )

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




############################################################### Explanation of how program works, the variables it uses; running the program and output it produces
#
#
# As a starting point, we begin with a set of SNPs that contribute either rare het counts or rare hom counts to a collection of DNA samples.
#
# Explanation of variables: $total_samples, $SNPs[$i], $i, $m 
#
# The user inputs the total number of DNA samples ($total_samples) and the number of each "type" of SNP that contributes counts to the samples. The SNP types 
# differ by whether they contribute 1, 2, 3, etc. counts to the total set of samples.  $SNPs[$i] contains the inputed number of SNPs contributing 
# $i counts where $i=1, 2, 3, etc.  Based on our experience, at least one SNP contributes counts at every integer-type from 1 to $m where $m is
# the number of different types of SNP.  Hence, both for program input and calculations, the program assumes that $i begins at 1 and that one or more SNPs contribute $i counts 
# at each consecutive integer value from $i=1 to $i=$m.  The sequence of prompts for which the user enters each value of $SNPs[$i] is terminated when the 
# user enters "0" or merely hits return in response the prompt: "enter number of SNPs with $i counts"
#
#
# Simulation of cumulative number of het or hom counts that occur in each sample in the DNA sample collection (explanation of the variables $sim_number, $counts_for_sample[$cc],
# $ascending_counts_for_sample[ ])
#
# The user inputs the total rounds of simulation ($sim_number) to be executed.  For each round of simulation, the program executes sampling without replacement from the counts 
# contributed by every SNP in $SNPs[$i] (see above) in order to simulate the total counts expected to accumulate in each DNA sample when the SNP counts are randomly sampled.  Random selection 
# of a sample belonging to $total_samples is accomplished by the program statement "$random_index[$k]=int(rand($total_samples))" which randomly samples an array element that corresponds 
# to one of the samples for each count contributed by a SNP belonging to the $SNPs[$i] distribution.
# 
# An underlying assumption in the random sampling is that every DNA sample has the same probability of receiving a count (i.e. a rare hom or rare het). This is a reasonable assumption under the null 
# hypothesis that all of the samples originate from a population that is (approximately) genetically homogeneous such as British Caucasians. In addition to this assumption and 
# the assumption of sampling of counts without replacement, each round of simulation also assumes that ALL counts derived from $SNPs[$i] (i.e. all rare homs or rare hets) are sampled 
# and end up being carried by one of the DNA samples.  This is simply because that is how we derive the distribution of counts in $SNPs[$i] in the first place, i.e., they are the total
# number of rare hom or rare het counts that are observed in the entire collection of DNA samples ($total_samples).  A further assumption is that the counts (i.e. rare alleles) at each SNP are inherited 
# independently of the alleles at the other SNPs that contribute rare counts.  This assumption holds if the particular SNPs that contribute counts to a particular sample are not in linkage disequilibrium (LD).
# (As an aside: This does not mean that the SNPs in $SNPs[$i] cannot be in LD, but does mean that when two SNPs contribute counts to a particular sample, we may want to only allot 1 count to that sample rather 
# than 2 if the two SNPs are in LD or perhaps close enough to be in LD - hence my idea which we discussed of tallying the number of counts for each sample (a)ignoring SNP proximity or (b) not tallying a second count
# for the sample, if the second SNP is less than a minimum distance [100,000 bp; 1,000,000 bp; 5,000,000 bp) from the nearest SNP that contributes a count to that sample.)
#
# Each round of simulation generates a distribution in which the total SNP counts are randomly distributed among the samples (at the end of each round, $counts_for_sample[$cc] contains the number of
# counts for each sample (numbered $cc=0 to $cc=$total_samples-1), and $ascending_counts_for_sample[ ] is a counterpart array that sorts the total counts in each sample in ascending order.  For each generated distribution (i.e.
# each round of simulation), the program adds to a running tally of the number of distributions/simulations observed to have a specific number of counts in a specific number of samples.  This running tally
# is stored as values of a hash called $sim_tabulation{hshkey} in which the hash key gives number of counts to the left of a decimal point and number of samples displaying that number of counts to the right of the decimal.
# For example, out of 1000 rounds of simulation, if exactly 105 samples displayed exactly 3 counts in 18 of the 1000 simulations, then $sim_tabulation{3.0105}=18.  At the end of the program, the values of 
# the $sim_tabulation{ } hash are printed in ascending hash key order in the output file so that the user can see results of the simulation. For example, 1000 simulations done for a sample set of 1024 samples produced the output
# below, which was part of the results for the number of simulations in which 3 or 4 counts occurred in a specific number of samples: 
#   
#
#		3.0104	19	 probab=0.01900000 
# 		3.0105	18	 probab=0.01800000 
# 		3.0106	13	 probab=0.01300000 
# 		3.0107	8	 probab=0.00800000 
# 		3.0108	9	 probab=0.00900000 
#		3.0109	3	 probab=0.00300000 
#		3.0110	7	 probab=0.00700000 
# 		3.0111	6	 probab=0.00600000 
# 		3.0112	2	 probab=0.00200000 
# 		3.0113	4	 probab=0.00400000 
# 		3.0114	3	 probab=0.00300000 
# 		3.0115	1	 probab=0.00100000 
# 		4.0012	1	 probab=0.00100000 
# 		4.0013	1	 probab=0.00100000 
# 		4.0016	2	 probab=0.00200000 
# 		4.0017	3	 probab=0.00300000 
# 		4.0018	7	 probab=0.00700000 
# 		4.0019	11	 probab=0.01100000 
# 		4.0020	14	 probab=0.01400000 
# 		4.0021	27	 probab=0.02700000 
#
#
#
# Prompt input to run the program
#
# To run the program, the user inputs the following information when prompted:
#
#	(1) Enter number of SNPs that contribute 1, 2, 3, etc. counts.  
#	    The user must enter a positive integer at each value (1, 2, 3, 4, etc).  The sequence of prompts is ended when the user hits return without entering a number.
#
#	(2) Enter total number of samples in the sample set or cohort. 
#	    Enter a positive integer.
#
#	(3) Enter number of rounds of simulation to be conducted. 
#	    Enter a positive integer.
#
#	(4) (OPTIONAL) Enter statistical cutpoints.
#	    Hit return to skip prompts for entering cutpoints, or enter "1" followed by return to choose the cutpoint option.
#	    Paired prompts allow the user to enter cutpoints defined by a specific number of counts and specific number of samples displaying that number of counts.
#	    For example, it may be of interest to know the number of times that the simulated distributions had 3 samples that displayed 25 counts.  This cutpoint
#	    would be entered as follows:
#
#  Enter integer counts displayed by sample (1 to n) - or just hit return to terminate cutpoint entry: 25<return>
#  Enter number of samples (1 to n) displaying 25 counts to further define the cutpoint: 3<return>
#
#  	    Up to 20 cutpoints can be entered.  To terminate the cutpoint entry prompts, just hit return at the first prompt in the pair without entering a number. 
#
#	    In addition to the sort of output show above (printout of the $sim_tabulation{ } hash), the program will calculate the number of simulations that produced samples with counts at or beyond each specified cutpoint.
#	    For example, if a cutpoint of 25 counts by 3 samples is entered, the program will count the number of simulations that produced 3 or more samples, each of which had at least 25 counts.
#
#
#	(5) A final prompt allows the user to re-enter the responses to the prompts (if there has been an error) or to proceed.  The prompt read as follows and is thus self explanatory:
#
#	"Hit return to continue; to reenter data, type any character followed by return"
#
#
#
# Output file
#
# A single output file is produced whose name has the form: "permut_sampXXX_simYYY_SNPs_AAA_BBB_timedate.txt"   where XXX is the number of samples, YYY is the number of simulations, 
# AAA is the number of SNPs contributing 1 count, BBB is the number of SNPs contributing $m counts, timedate is time/day information so that the output file is unique and not overwritten when the program is rerun.
# 
# Content of the output file is annotated and its main components are a printout of the $sim_tabulation{ } hash is ascending hash key order as described and shown above; and summing of counts and probabilities that
# are at or more extreme than the inputted cutpoints, also described above.
#
#
#
#
#
#








