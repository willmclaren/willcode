#!/usr/bin/perl

while(<>) {

	chomp;
	
	next unless /\d/;
	
	if(/marker/i) {
		$marker_num = (split /markers?\s+/, $_)[-1];
		$marker_num =~ s/\s+$//g;
	}
	
	if(/^LRS/) {
		@data = split / /, $_;
		
		$lrs = $data[2];
		$p = $data[-1];
		
		print ($map{$marker_num} ? $map{$marker_num} : $marker_num)."\t$lrs\t$p";
		
		# get crap out the way
		$crap = <>;
		$crap = <>;
		
		# now read the allele data
		$read = <>;
		
		while($read !~ /^\-+/) {
			@bits = split /\s+/, $read;
			
			print "\t".(join "\t", @bits);
			
			$read = <>;
		}
		
		print "\n";
	}
}	