#!/usr/bin/perl

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$stem = shift @ARGV;

# check the existence of the ped and map files
if(!open IN, $stem.".ped") {
	die "Could not find $stem\.ped\n";
}
close IN;

if(!open IN, $stem.".map") {
	die "Could not find $stem\.map\n";
}
close IN;

# frequency
system qq/plink --allow-no-sex --noweb --file $stem --out $stem --all --freq/;
system qq/fix.plink.output.pl $stem.frq | cut -f 2-5 > frq/;

system qq/fix.plink.output.pl $stem.ped | cut -f 1,2,6 > $stem.cc.clst/;
system qq/plink --allow-no-sex --noweb --file $stem --out $stem --all --freq --within $stem.cc.clst/;
system qq/fix.plink.output.pl $stem.frq.strat | cut -f 2,6 > a; merge.files.pl frq a | uniq > frq2/;

open PIPE, qq/merge.files.pl \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/HapMap\/HapMap.frq frq2 | cut -f 1-6,9 |/;
open OUT, ">$stem\.flag\.freq" or die "Could not write to file $stem.flag.freq\n";
while(<PIPE>) {
# 	print;
	chomp;
	($snp, $ha, $hb, $hf, $a, $b, $f) = split /\t/, $_;
	next if (($a == 0) || ($b == 0));
	
	$diff = $hf - $f;
	$diff = 0 - $diff if $diff < 0;
	print "DIFF: $snp $diff\n" if $diff > 0.1;
	print OUT "$snp\n" if $diff > 0.1;
}
close OUT;
close PIPE;

# HWE/counts
system qq/plink --allow-no-sex --noweb --file $stem --out $stem --all --hardy/;
system qq/fix.plink.output.pl $stem.hwe | cut -f 1,6 > a; merge.files.pl a | uniq > hwe/;
system qq/check.column.pl -c 4 -l 0.0001 hwe | check.column.pl -c 4 -v 0 | cut -f 1 > $stem.flag.hwe/;
system qq/fix.plink.output.pl $stem.hwe | cut -f 1,3 > a; merge.files.pl a | uniq > counts/;


# missingness
system qq/plink --allow-no-sex --noweb --file $stem --out $stem --all --missing/;
system qq/fix.plink.output.pl $stem.lmiss | cut -f 2,4 > miss/;
system qq/plink --allow-no-sex --noweb --file $stem --out $stem.clst --all --missing --within $stem.cc.clst/;
system qq/fix.plink.output.pl $stem.clst.lmiss | cut -f 2,3,6 > a; merge.files.pl a | uniq | cut -f 1,3,5 > missdiff/;

open IN, qq/missdiff/;
open OUT, ">$stem\.flag\.diff" or die "Could not write to file $stem.flag.diff\n";
while(<IN>) {
# 	print;
	chomp;
	($snp, $a, $b) = split /\t/, $_;
	
	$diff = $a - $b;
	$diff = 0 - $diff if $diff < 0;
	print "DIFF: $snp $diff\n" if $diff > 0.05;
	print OUT "$snp\n" if $diff > 0.05;
}
close OUT;
close IN;

system qq/check.column.pl -c 2 -v 1 -e miss | cut -f 1 > ungenotyped.snps/;
system qq/plink --allow-no-sex --noweb --file $stem --out $stem.no.ungen --all --missing --exclude ungenotyped.snps/;

system qq/fix.plink.output.pl $stem.lmiss | check.column.pl -c 4 -g 0.1 | cut -f 2 > $stem.flag.missing/;
system qq/fix.plink.output.pl $stem.no.ungen.imiss | check.column.pl -c 5 -g 0.1 | cut -f 1 > $stem.samples.flag.missing/;


# model
system qq/plink --allow-no-sex --noweb --file $stem --out $stem --all --model/;
system qq/fix.plink.output.pl $stem.model | cut -f 2,8 > a; merge.files.pl a | uniq > model/;

# combine flag files
system qq/perl ~\/scripts\/CHD.flags.pl $stem/;

# do LD
system qq/check.column.pl -c 6 -v 1 -e $stem.ped > $stem.ctrls.ped; check.column.pl -c 6 -v 2 -e $stem.ped > $stem.cases.ped/;

system qq/java -jar -Xmx1500m \/nfs\/team71\/psg\/wm2\/Software\/Haploview\/Haploview.jar -memory 1500 -pedfile $stem.ped -info \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/haploview.info -n -dprime -skipcheck/;
system qq/cut -f 1,2,5 $stem.ped.LD | awk '{print \$1 "_" \$2,\$3}' | tr " " "\\t" | sed "s\/r\^2\/r\^2_all\/" > $stem.all.ld/;

system qq/java -jar -Xmx1500m \/nfs\/team71\/psg\/wm2\/Software\/Haploview\/Haploview.jar -memory 1500 -pedfile $stem.ctrls.ped -info \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/haploview.info -n -dprime -skipcheck/;
system qq/cut -f 1,2,5 $stem.ctrls.ped.LD | awk '{print \$1 "_" \$2,\$3}' | tr " " "\\t" | sed "s\/r\^2\/r\^2_controls\/" > $stem.ctrls.ld/;

system qq/java -jar -Xmx1500m \/nfs\/team71\/psg\/wm2\/Software\/Haploview\/Haploview.jar -memory 1500 -pedfile $stem.cases.ped -info \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/haploview.info -n -dprime -skipcheck/;
system qq/cut -f 1,2,5 $stem.cases.ped.LD | awk '{print \$1 "_" \$2,\$3}' | tr " " "\\t" | sed "s\/r\^2\/r\^2_cases\/" > $stem.cases.ld/;

system qq/merge.files.pl -v "NA" -b $stem.all.ld $stem.cases.ld $stem.ctrls.ld | sed "s\/_rs\/\\trs\/" | sed "s\/_L\/\\tL\/" | add.info.pl \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/include.snps.info | add.info.pl -c 2 \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/include.snps.info | cut -f 1-6,8 | perl \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/ld.script | move.col.pl 6 1 | cut -f 1-6 | sed "s\/\\tL1\\tL2\/Chr\\tMarker_A\\tMarker_B\/" > LD/;

# make the excel file
if(!$args{'n'}) {
	print qq/merge.files.pl -v "NA" -b \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/include.snps.info frq2 \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/HapMap\/frq counts hwe miss missdiff model > SNP\\ QC; make.excel.pl $stem.QC.xls SNP\\ QC LD\n/;
	system qq/merge.files.pl -v "NA" -b \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/include.snps.info frq2 \/nfs\/team71\/psg\/wm2\/Cardiogenics\/WIP\/HapMap\/frq counts hwe miss missdiff model > SNP\\ QC; make.excel.pl $stem.QC.xls SNP\\ QC LD/;
}
