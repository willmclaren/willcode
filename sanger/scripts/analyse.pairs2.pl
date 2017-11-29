#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	next if /NN/;
	next if /Reading/;

	chomp;
	
	($snpa, $snpb, $genoa, $genob, $count) = split /\t/, $_;
	
	next unless (($genoa =~ /a|c|g|t/i) && ($genob =~ /a|c|g|t/i));
	
	$counts{$snpa."\t".$snpb}{$genoa}{$genob} = $count;
	
	$present{$snpa} = 1;
	$present{$snpb} = 1;
}

close IN;


foreach $pair(keys %counts) {
	($snpa, $snpb) = split /\t/, $pair;

	foreach $genoa(keys %{$counts{$pair}}) {
		$major = (sort {$counts{$pair}{$genoa}{$a} <=> $counts{$pair}{$genoa}{$b}} keys %{$counts{$pair}{$genoa}})[-1];
		
		$ref{$snpa}{$snpb}{$genoa}{$major} = 1;
	}
}


our %out;

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $qual) = split /\t/, $_;
	
	next unless $present{$snp};
	
	if($sample ne $prev) {
		analyse(\%data, \%ref);
		
		%data = ();
	}
	
	$data{$snp}{'geno'} = $geno;
	$data{$snp}{'qual'} = $qual;
	$prev = $sample;
}

analyse($prev, \%data);

foreach $snpa(keys %ref) {
	foreach $snpb(keys %{$ref{$snpa}}) {
		print
			"$snpa\t$snpb".
			
			# counts
			"\t".$out{'right'}{$snpa}{$snpb}{'count'}.
			"\t".$out{'wrong'}{$snpa}{$snpb}{'count'}.
			"\t".$out{'null'}{$snpa}{$snpb}.
			
			# right
			"\t".($out{'right'}{$snpa}{$snpb}{'totala'}/$out{'right'}{$snpa}{$snpb}{'count'}).
			"\t".($out{'right'}{$snpa}{$snpb}{'totalb'}/$out{'right'}{$snpa}{$snpb}{'count'}).
			"\t".$out{'right'}{$snpa}{$snpb}{'abest'}.
			"\t".$out{'right'}{$snpa}{$snpb}{'bbest'}.
			
			# wrong
			"\t".($out{'wrong'}{$snpa}{$snpb}{'totala'}/$out{'wrong'}{$snpa}{$snpb}{'count'}).
			"\t".($out{'wrong'}{$snpa}{$snpb}{'totalb'}/$out{'wrong'}{$snpa}{$snpb}{'count'}).
			"\t".$out{'wrong'}{$snpa}{$snpb}{'abest'}.
			"\t".$out{'wrong'}{$snpa}{$snpb}{'bbest'}."\n";
	}
}



sub analyse() {
	my $data = shift @_;
	my $ref = shift @_;
	
	my $genoa, $genob, $quala, $qualb;
	
	foreach my $snpa(keys %$ref) {
		foreach my $snpb(keys %{$ref->{$snpa}}) {
			$genoa = $data->{$snpa}{'geno'};
			$genob = $data->{$snpb}{'geno'};
			
			$quala = $data->{$snpa}{'qual'};
			$qualb = $data->{$snpb}{'qual'};
			
			if(($genoa =~ /n/i) || ($genob =~ /n/i)) {
				$out{'null'}{$snpa}{$snpb}++;
			}
			
			elsif($ref->{$snpa}{$snpb}{$genoa}{$genob}) {
				$out{'right'}{$snpa}{$snpb}{'totala'} += $quala;
				$out{'right'}{$snpa}{$snpb}{'totalb'} += $qualb;
				
				if($quala > $qualb) {
					$out{'right'}{$snpa}{$snpb}{'bbest'}++;
				}
				
				else {
					$out{'right'}{$snpa}{$snpb}{'abest'}++;
				}
				
				$out{'right'}{$snpa}{$snpb}{'count'}++;
			}
			
			else {
				$out{'wrong'}{$snpa}{$snpb}{'totala'} += $quala;
				$out{'wrong'}{$snpa}{$snpb}{'totalb'} += $qualb;
				
				if($quala > $qualb) {
					$out{'wrong'}{$snpa}{$snpb}{'bbest'}++;
				}
				
				else {
					$out{'wrong'}{$snpa}{$snpb}{'abest'}++;
				}
				
				$out{'wrong'}{$snpa}{$snpb}{'count'}++;
			}
		}
	}
}