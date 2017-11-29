#!/usr/bin/perl

while(<>) {
	chomp;
	
	($group, $chrom, $from, $to) = split /\t/, $_;
	
	for($first=$from;$first<$to;$first++) {
		$second = $first + 1;
		
		open PIPE, "cocaphase ../../input/dvh.v1/Chroms/chr$chrom.recode.ped -window 2 -marker $first $second -permutation 10 |";
		#print "cocaphase ../../input/Chroms/chr$chrom.recode.ped -window 2 -marker $first $second -permutation 1000 |\n";
		
		while(<PIPE>) {
			chomp;
			
			next unless /\d/;
			
			if(/^LRS/) {
				@data = split / /, $_;
				
				$lrs = $data[2];
				$p = $data[-1];
				
				print "$group\t$chrom\t$first\t$second\t".($map{$marker_num} ? $map{$marker_num} : $marker_num)."\t$lrs\t$p";
				
				# get crap out the way
				$crap = <PIPE>;
				$crap = <PIPE>;
				
				# now read the allele data
				$read = <PIPE>;
				print OUT $read if $args{'w'};
				
				while($read !~ /^\-+/) {
					@bits = split /\s+/, $read;
					
					print "\t".(join "\t", @bits);
					
					$read = <PIPE>;
				}
			}
			
			if(/^Best/) {
				$p = (split /\s+/, $_)[-1];
				print "\t$p";
			}
			
			if(/^Global/) {
				@data = split /\s+/, $_;
				print "\t$data[2]\t$data[4]\n";
			}
		}
		
		close PIPE;
	}
}