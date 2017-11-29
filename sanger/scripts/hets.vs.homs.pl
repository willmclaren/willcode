#!/usr/bin/perl

while(<>) {
	chomp;
	@data = split /\t/, $_;
	$snp = shift @data;
	$cr = shift @data;
	$ratio = shift @data;
	$count = shift @data;
	
	while(@data) {
		$geno = shift @data;
		$qual = shift @data;
		$num = shift @data;
		
		if($geno =~ /n/i) {
			$quals{"n"}+= $qual;
			$counts{"n"}++;
		}
		
		elsif(substr($geno,0,1) ne substr($geno,1,1)) {
			$quals{"het"}+=$qual;
			$counts{"het"}++;
		}
		
		else {
			$quals{"hom"}+=$qual;
			$counts{"hom"}++;
		}
	}
}

print "NN\t".($quals{"n"}/$counts{"n"})."\t".$counts{"n"}."\n";
print "Hets\t".($quals{"het"}/$counts{"het"})."\t".$counts{"het"}."\n";
print "Homs\t".($quals{"hom"}/$counts{"hom"})."\t".$counts{"hom"}."\n";