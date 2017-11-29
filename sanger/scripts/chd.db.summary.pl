#!/usr/bin/perl

$head = <>;
chomp $head;
@headers = split /\t/, $head;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	$id = $data[4];
	
	foreach $header(@headers) {
		$data{$id}{$header} = shift @data;
		
		if($header =~ /^rs/) {
			$f{$header}{$data{$id}{$header}}++ unless (($data{$id}{$header} =~ /n|0|9|\-/i) || (substr($data{$id}{$header},0,1) ne substr($data{$id}{$header},1,1)));
		}
	}
}
	

foreach $id(keys %data) {
	$arr{$data{$id}{'ccgroupcxch'}}{$data{$id}{'ethnicitycxch'}}{$data{$id}{'sexcx'}}{$id} = 1;
}

foreach $ccg(keys %arr) {
	foreach $eth(keys %{$arr{$ccg}}) {
		foreach $sex(keys %{$arr{$ccg}{$eth}}) {
			foreach $snp(@headers) {
				next unless $snp =~ /^rs/;
					
				($a, $b) = sort {$f{$snp}{$a} <=> $f{$snp}{$b}} keys %{$f{$snp}};
				
				$alleles = "$a\t$b";
				$alleles =~ tr/1234/ACGT/;
				
				print "$ccg\t$eth\t$sex\t$snp\t$alleles";
				
				foreach $cc('cadcxyn', 'micxyn') {
				
					%counts = ();
					%by = ();
					%hets = ();
					%total = ();
					$hets = 0;
					$total = 0;
					
					foreach $sample(keys %{$arr{$ccg}{$eth}{$sex}}) {
						$allele = $data{$sample}{$snp};
						
						next if $allele =~ /n|0|9|\-/i;
						
						if(substr($allele,0,1) eq substr($allele,1,1)) {
							$counts{$allele}++;
							$by{$data{$sample}{$cc}}{$allele}++;
						}
						
						else {
							$hets++;
							$hets{$data{$sample}{$cc}}++;
						}
						
						$total++;
						$total{$data{$sample}{$cc}}++;
					}
					
					print
						"\tALL\t".
						($counts{$a} ? $counts{$a} : 0)."\t".
						($hets ? $hets : 0)."\t".
						($counts{$b} ? $counts{$b} : 0);
					
					foreach $s(0,1,-9) {
						print
							"\tCC\_".$s."\t".
							($by{$s}{$a} ? $by{$s}{$a} : 0)."\t".
							($hets{$s} ? $hets{$s} : 0)."\t".
							($by{$s}{$b} ? $by{$s}{$b} : 0);
					}
				}
				
				print "\n";
			}
		}
	}
}