#!/usr/bin/perl

while(<>) {
	chomp;
	
	@snps = split /\s+|\||\_/, $_;
	
	$window_size = scalar @snps;
	
	# write a list of SNPs for PLINK to extract
	open OUT, ">$snps[0]\.$window_size\.temp.list";
	foreach $snp(@snps) {
		print OUT "$snp\n";
	}
	close OUT;
	
	# make the PED file using PLINK
	system("plink --noweb --tab --bfile /lustre/work1/sanger/wm2/Illumina/input/dvh.v1/merge_mind005_geno005_finalqc --recode --extract $snps[0]\.$window_size\.temp.list --out $snps[0]\.$window_size\.temp --silent");
	
	# delete the list file
	system("rm $snps[0]\.$window_size\.temp.list");
	
	# read in the constructed PED file
	open IN, "$snps[0]\.$window_size\.temp.recode.ped" or die "Could not open recoded file $snps[0]\.$window_size\.temp.recode.ped\n";
	
	while(<IN>) {
		chomp;
		
		@data = split /\t/, $_;
		
		$sample = $data[0];
		
		@fam = ();
		for(1..5) {
			push @fam, shift @data;
		}
		
		$fam{$sample} = join "\t", @fam;
		$aff{$sample} = shift @data;
		
		@gen = ();
		while(@data) {
			push @gen, shift @data;
		}
		
		$gen{$sample} = join "\t", @gen;
	}
	
	close IN;
	
	$best = 1;
	
	for $perm(1..1000) {
		
		# rearrange the data
		@keys = keys %aff;
		
		for $i(0..$#keys) {
			$j = int(rand(scalar @keys));
			
			$temp = $aff{$i};
			$aff{$i} = $aff{$j};
			$aff{$j} = $temp;
		}
		
		# now write it out
		open OUT, ">$snps[0]\.$window_size\.temp.sim.ped";
		
		foreach $sample(@keys) {
			print OUT "$fam{$sample}\t$aff{$sample}\t$gen{$sample}\n";
		}
		
		close OUT;
		
		# now run PLINK
		system("plink --noweb --ped $snps[0]\.$window_size\.temp.sim.ped --map $snps[0]\.$window_size\.temp.recode.map --hap-assoc --hap-window $window_size --out $snps[0]\.$window_size\.temp.sim --silent");
		
		# now read in the result
		open PIPE, "fix.plink.output.pl $snps[0]\.$window_size\.temp.sim.assoc.hap |";
		
		while(<PIPE>) {
			next unless /OMNIBUS/;
			
			chomp;
			
			@data = split /\t/, $_;
			
			$p = $data[6];
			
			if($p && ($p < $best)) {
				$best = $p;
			}
		}
		
		close PIPE;
	}
	
	print (join '|', @snps);
	print "\t$best\n";
}