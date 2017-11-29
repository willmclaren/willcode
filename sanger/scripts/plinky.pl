#!/usr/bin/perl

for $i(1..5) {
	for $j(($i+1)..5) {
		print "\tRunning PLINK\n";
		system("bsub -P rdgroup -J h$i\.$j -o out plink --noweb --ped $i\.$j\.recode.ped --map $i.recode.map --hardy --out $i\.$j");
		system("bsub -P rdgroup -J f$i\.$j -o out plink --noweb --ped $i\.$j\.recode.ped --map $i.recode.map --freq --out $i\.$j");
	}
}