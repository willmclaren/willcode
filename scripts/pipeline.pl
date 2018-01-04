#!/usr/bin/perl

%args_with_vals = (
	'j' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


$args{'j'} = "default" unless $args{'j'};



# split the files and reorder by sample
system("echo \"split.by.col.pl -c 2 Affx*.txt; cat *.split > $args{'j'}\.g; rm *.split\" | bsub -P rdgroup -J split$args{'j'} -o $args{'j'}\.out");
# 
# sleep 15;
# 
# # convert to outlier format
system("bsub -P rdgroup -J prep$args{'j'} -o $args{'j'}\.out -w 'done(split$args{'j'})' prep.outlier.pl -l ~/Farm/work/Affy/data/snps.noX.noSNP.list -s ~/Farm/work/Affy/data/snp.info -o $args{'j'} $args{'j'}\.g");
# 
# sleep 15;

# # convert to outlier format (all SNPs)
# system("bsub -P rdgroup -J prep$args{'j'}all -o $args{'j'}\.out -w 'done(split$args{'j'})' prep.outlier.pl -l ~/Farm/work/Affy/data/snp.info -s ~/Farm/work/Affy/data/snp.info -o $args{'j'}.all $args{'j'}\.g");
# 
# # convert from outlier format to PED (all SNPs)
# system("echo \"out2ped.pl $args{'j'}.all.data > $args{'j'}.all.ped\" | bsub -P rdgroup -J o2p$args{'j'}all -o $args{'j'}\.out -w 'done(prep$args{'j'}all)'");
# 
# # make map file
# system("echo \"add.col.pl 0 $args{'j'}.all.map | switch.cols.pl 1 3 > $args{'j'}.all.map\" | bsub -P rdgroup -J map$args{'j'}all -o $args{'j'}\.out -w 'done(prep$args{'j'}all)'");

# run outlier program
system("bsub -P rdgroup -J outl$args{'j'} -o $args{'j'}\.out -w 'done(prep$args{'j'})' outlier -f -d 100000,1000000,5000000 -o $args{'j'} $args{'j'}\.info $args{'j'}\.data");
#system("bsub -P rdgroup -J outl$args{'j'} -o $args{'j'}\.out outlier -f -d 100000,1000000,5000000 -o $args{'j'} $args{'j'}\.info $args{'j'}\.data");

#sleep 15;

# look at genotype quality in hets
system("echo  \"perl ~/bin/quals.in.hets.pl $args{'j'}\_full.sample.dist $args{'j'}\.g > $args{'j'}\.quals.in.hets\" | bsub -P rdgroup -J hetq$args{'j'} -o $args{'j'}\.out -w 'done(outl$args{'j'})'");

if($args{'r'}) {
	# look at concordance between r2=1 SNPs
	system("echo \"perl ~/scripts/count.pairs.pl ~/Farm/work/Concordance/Ilmn550k.vs.Affy500k/CEU.CHB.JPT.YRI.pairs $args{'j'}\.info $args{'j'}\.data > $args{'j'}\.r2_1_all.counts\" | bsub -P rdgroup -J count$args{'j'} -o $args{'j'}\.out -w 'done(prep$args{'j'})' ");
	
# 	system("echo \"perl ~/scripts/count.pairs.pl ~/Farm/work/Concordance/Ilmn550k.vs.Affy500k/CEU.CHB.JPT.YRI.pairs $args{'j'}\.info $args{'j'}\.data > $args{'j'}\.r2_1_all.counts\" | bsub -P rdgroup -J count$args{'j'} -o $args{'j'}\.out");
	

	#sleep 15;

	system("echo \"perl ~/scripts/analyse.pairs.pl $args{'j'}\.r2_1_all.counts $args{'j'}\.info $args{'j'}\.data > $args{'j'}\.r2_1_all.results\" | bsub -P rdgroup -J an$args{'j'} -o $args{'j'}\.out -w 'done(count$args{'j'})'");
}
