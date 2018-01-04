#!/usr/bin/perl

%args_with_vals = (
	'c' => 1,
	'a' => 1,
);

$args{'c'} = "58C";
$args{'a'} = "BRLMM";

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$root = "/lustre/work1/sanger/wm2/Affy/data";
$hap = "/lustre/work1/sanger/wm2/HapMap/Frequencies";
$eth = "/lustre/work1/sanger/wm2/Affy/data/58C/BRLMM/WTCCC89297/eth.markers";


$id = shift @ARGV;

die "No sample ID specified\n" unless $id;


# get genotypes
print "Grepping genotypes\n";
system "grep $id $root/$args{'c'}/$args{'a'}/$args{'c'}.$args{'a'}.hapmap.g > $id.g";

# run plot.ethnic
foreach $pop(qw/CHB JPT YRI/) {
	print "Checking ethnic markers for $pop\n";
	system "plot.ethnic.pl -r CEU -e $pop -s $root/snp.info -l $hap/HapSNPs_CEUmono_".$pop."maf40.noX.list -f $hap/Frequencies/subset.freqs -o $id.$pop $id.g";
	system "cut -f 1,4 $id.".$pop."_eth.list > $id.$pop";
	system "rm $id.".$pop."_* $id.".$pop.".html";
}

system "rm $id.g";

# get the hets/homs for this cohort
print "Getting het data\n";
system "cut -f 2 $root/$args{'c'}/$args{'a'}/$args{'c'}.$args{'a'}_full.sample.dist | sort -u | add.col.pl -e 1 > $args{'c'}.hetshoms";

# get the hets for this sample
system "grep HET $root/$args{'c'}/$args{'a'}/$args{'c'}.$args{'a'}_full.sample.dist | grep $id | cut -f 2 | add.col.pl -e 1 > $id.hets";

# get the homs for this sample
system "grep HOM $root/$args{'c'}/$args{'a'}/$args{'c'}.$args{'a'}_full.sample.dist | grep $id | cut -f 2 | add.col.pl -e '1.1' > $id.homs";

system "cat $id.homs $id.hets > $id.hetshoms; rm $id.hets; rm $id.homs";

# get the quality scores
print "Getting quality scores\n";
system "gzcat $root/$args{'c'}/$args{'a'}/$args{'c'}.$args{'a'}.g.gz | grep $id | list.grep.pl $id.hetshoms | cut -f 1,4 > $id.qual";

# make a list of SNPs
system "cat $eth $args{'c'}.hetshoms | cut -f 1 | sort -u > $id.list";

# merge the files
print "Merging files\n";
system "merge.files.pl -b $id.list $args{'c'}.hetshoms $id.hetshoms $id.CHB $id.JPT $id.YRI $id.qual | cut -f 1,3- | fill.blanks.pl | fill.blanks.pl > $id.data";

system "rm $id.CHB $id.JPT $id.YRI";
system "rm $id.qual $id.hetshoms";

# run the plotting program
# print "Plotting data on chromosomes\n";
# system "plot.data.on.chrom.pl -s $root/snp.info -nl -nm -min 0,0,0,0,0,0,0 -max 4,1.1,3.4,3.4,3.4,0.5,0.5 -o $id $id.data";

print "Drawing chromosome picture\n";
system "pic.pl -o $id -nj $id\.data";

# # copy files to Plots dir
# system "cp ".$id."*png ~/Documents/Plots/";
# system "cp $id.html ~/Documents/Plots/";

# system "tar -cf $id.tar ".$id."*png $id.html";
# system "rm ".$id."*png $id.html";
system "rm $id.list";


