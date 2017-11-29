#!/usr/bin/perl

for $i(1..5) {
	for $j(($i+1)..5) {
		
		print "Combining $i and $j\n";
		
		print "\tRe-writing files\n";
	
		# first change affected status in the second file
		open IN, "$j.recode.ped";
		open OUT, ">$i\.$j\.temp.ped";
		
		while(<IN>) {
			chomp;
			@data = split /\s+/, $_;
			
			$data[5] = 2;
			
			print OUT (join " ", @data);
			print OUT "\n";
		}
		
		close OUT;
		
		print "\tCombining and running PLINK\n";
		
		system("cat $i.recode.ped $i\.$j\.temp.ped > $i\.$j\.recode.ped");
		system("bsub -P rdgroup -J $i\.$j -o out plink --noweb --ped $i\.$j\.recode.ped --map $i.recode.map --model --out $i\.$j");
	}
}