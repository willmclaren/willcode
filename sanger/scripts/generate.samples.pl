#!/usr/bin/perl


$args{'n'} = 10;
$args{'a'} = "CEU";
$args{'b'} = "YRI";


%args_with_vals = (
	'n' => 1,
	'a' => 1,
	'b' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$count = $args{'n'};
$popa = $args{'a'};
$popb = $args{'b'};



foreach $num(1..$count) {
	print "Generating sample no. $num ...\n";

	$i1 = int(rand(60));
	$i2 = int(rand(60));

	foreach $chrom(1..22) {
		system("cross.hapmap.pl -i1 $i1 -i2 $i2 -l1 genotypes_chr".$chrom."_".$popa."_r21_nr_fwd_legend_all -p1 genotypes_chr".$chrom."_".$popa."_r21_nr_fwd_phased_all -s1 genotypes_chr".$chrom."_".$popa."_r21_nr_fwd_sample.txt -l2 genotypes_chr".$chrom."_".$popb."_r21_nr_fwd_legend_all -p2 genotypes_chr".$chrom."_".$popb."_r21_nr_fwd_phased_all -s2 genotypes_chr".$chrom."_".$popb."_r21_nr_fwd_sample.txt -o $popa\.$popb\.$num\.chr$chrom");
	}
	
	system("cat $popa\.$popb\.$num\.chr\*\.g > ../Crosses/$popa\.$popb\.$num\.g");
	system("rm $popa\.$popb\.$num\.chr\*\.g");
}
