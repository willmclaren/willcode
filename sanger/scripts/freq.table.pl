#!/usr/bin/perl

$first = 1;

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	if($first) {
		foreach $item(@data) {
			next unless $item =~ /\_/;
			
			@split = split /\_/, $item;
			
			$cc = pop @split;
			$plate = join "\_", @split;
			
			$plates{$plate} = 1;
		}
		
		@plates = sort {$a <=> $b} keys %plates;
		
		print "SNP";
		
		foreach $plate(@plates) {
			print "\t$plate\_1\t$plate\_2";
		}
		
		print "\n";
		
		$first = 0;
	}
	
	$snp = shift @data;
	print $snp;
	
	%data = ();
	
	while(@data) {
		$plate = shift @data;
		$f = shift @data;
		
		$data{$plate} = $f;
	}
	
	foreach $p(@plates) {
		$plate = $p."\_1";		
		print "\t".($data{$plate} ? $data{$plate} : "-");
		
		$plate = $p."\_2";		
		print "\t".($data{$plate} ? $data{$plate} : "-");
	}
	
	print "\n";
}