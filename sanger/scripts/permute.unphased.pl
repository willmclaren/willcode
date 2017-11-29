#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chr, $snp, $crap, $pos, $num) = split /\t/, $_;
	
	$chr{$snp} = $chr;
	$num{$snp} = $num;
}

close IN;



while(<>) {
	chomp;
	
	@snps = split /\s+|\||\_/, $_;
	
	$window = scalar @snps;
	
	@markers = ();
	foreach $snp(@snps) {
		push @markers, $num{$snp};
	}
	
	$chr = $chr{$snps[0]};
	$markers = join " ", @markers;
		
	open PIPE, "unphased -window $window -marker $markers -permutation 1000 Chroms/chr$chr.recode.ped |";
	#print "unphased -window $window -marker $markers -permutation 100 ../../input/dvh.v1/Chroms/chr$chr.recode.ped |";
	
	open OUT, ">Full/".(join '_', @snps).".full.output";
	
	while(<PIPE>) {
		print OUT $_;
	
		chomp;
		
		next unless /\d/;
		
		if(/^Best/) {
			@data = split /\s+/, $_;
			
			$p = $data[-1];
			
			print (join '_', @snps);
			print "\t$p";
			
			$adj = <PIPE>;
			print OUT $adj;
			chomp $adj;
			
			@data = split /\s+/, $adj;
			$adp = $data[-4];
			$se = $data[-1];
			
			print "\t$adp\t$se";
			
			$emp = <PIPE>;
			print OUT $emp;
			chomp $emp;
			
			$emp = (split /\s+/, $emp)[-1];
			
			print "\t$emp\n";
		}
	}
	
	close PIPE;
	
	close OUT;
}