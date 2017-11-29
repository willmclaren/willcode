#!/usr/bin/perl

open OUT, ">scores";

while(<>) {
	chomp;
	
	$snp = (split /\t|\,/, $_)[0];
	
	open TEMP, ">temp_a";
	print TEMP "set xrange \[0\:3\]\nset yrange \[0\:3\]\nplot \"/nfs/wtccc/data1/mi1/Obesity/OBC_normalized_CELs/SNP_intensities\/$snp.i\" using 2\:3\npause mouse";
	close TEMP;
	
	open TEMP, ">temp_b";
	print TEMP "set xrange \[0\:3\]\nset yrange \[0\:3\]\nplot \"/nfs/wtccc/data1/mi1/Obesity/OB_normalized_CELs/SNP_intensities\/$snp.i\" using 2\:3\npause mouse";
	close TEMP;
	
	system("gnuplot temp_a");
	system("gnuplot temp_b");
	
	print "Score for $snp: ";
	$score = <STDIN>;
	
	print OUT "$snp\t$score";
}

close OUT;