#!/usr/bin/perl

open IN, shift @ARGV;

$head = <IN>;
chomp $head;
@header = split /\t/, $head;
print shift @header;

foreach $head(@header) {
	print "\t$head\tLow\tHigh\tOK";

	@split = split /\_/, $head;
	
	pop @split;
	
	$plate = (join "\_", @split);
	
	push @plates, $plate unless $plate eq $plates[-1];
}

print "\n";

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	
	push @snps, $snp;
	
	foreach $head(@header) {
		$d = shift @data;
		
		$data{$snp}{$head} = $d;
	}
}

close IN;

open OUT, ">debug";

foreach $snp(@snps) {
	print $snp;

	foreach $plate(@plates) {
		foreach $cc(1,2) {
			
			next if  $data{$snp}{$plate."_".$cc} eq '-';
		
			$count = 0;
			$mean = 0;
			$var = 0;
		
			foreach $p(@plates) {
				next if $p eq $plate;
				
				next if $data{$snp}{$p."_".$cc} eq '-';
				
				$mean += $data{$snp}{$p."_".$cc};
				$count++;
			}
			
			$mean /= $count;
			
			foreach $p(@plates) {
				next if $p eq $plate;
				
				next if $data{$snp}{$p."_".$cc} eq '-';
				
				$var += (($data{$snp}{$p."_".$cc} - $mean) * ($data{$snp}{$p."_".$cc} - $mean));
			}
			
			$var /= $count;
			
			$sd = sqrt($var);
			
			$ci = 1.96 * ($sd / sqrt($count));
			
			$low = $data{$snp}{$plate."_".$cc} - $ci;
			$high = $data{$snp}{$plate."_".$cc} + $ci;
			
			$ok = ((($data{$snp}{$plate."_".$cc} > $low) && ($data{$snp}{$plate."_".$cc} < $high)) ? 1 : 0);
			
			print OUT "$snp\t$plate\_$cc\t".$data{$snp}{$plate."_".$cc}."\t$low\t$high\t$ok\n";
			
			print "\t".$data{$snp}{$plate."_".$cc}."\t$low\t$high\t$ok";
		}
	}
	
	print "\n";
}