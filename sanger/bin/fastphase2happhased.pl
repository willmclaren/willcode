#!/usr/bin/perl

%args_with_vals = (
	'o' => 1,
);

$args{'o'} = "hap.phased";

# get the arguments into the hash
while($ARGV[0] =~ /^\-.+/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data == 4) {
		push @snps, $data[1];
		$pos{$data[1]} = $data[3];
	}
	
	else {
		push @snps, $data[0];
		$pos{$data[1]} = $data[2];
	}
}

close IN;


$read = 0;

open PHA, ">".$args{'o'}.".phased_all";

while(<>) {
	if($read) {
		chomp;
		last if /END GENOTYPES/;
		push @samples, $_;
		
		for(1..2) {
			$a = <>;
			chomp $a;
			
			@data = split /\s+/, $a;
			
			$first = 1;
			
			foreach $snp(@snps) {
				$b = shift @data;
				
				if($seen{$snp}{$b}) {
					print PHA ($first ? "" : " ");
					print PHA ($seen{$snp}{$b} - 1);
				}
				
				else {
					if(scalar keys %{$seen{$snp}} >= 1) {
						print PHA ($first ? "" : " ");
						print PHA "1";
						$seen{$snp}{$b} = 2;
					}
					
					else {
						print PHA ($first ? "" : " ");
						print PHA "0";
						$seen{$snp}{$b} = 1;
					}
				}
					
				$first = 0 if $first;
			}
			
			print PHA "\n";
		}
	}
	
	else {
		$read = 1 if /^BEGIN GENOTYPES/;
	}
}

close PHA;


open SAM, ">".$args{'o'}.".sample.txt";

foreach $s(@samples) {
	print SAM "$s 0\n";
}

close SAM;

open SNP, ">".$args{'o'}.".legend_all";

print SNP "rs position a0 a1\n";

foreach $snp(@snps) {
	%temp = ();

	foreach $a(keys %{$seen{$snp}}) {
		$temp{$seen{$snp}{$a}} = $a;
	}

	print SNP "$snp $pos{$snp} ".($temp{'1'} ? $temp{'1'} : "-")." ".($temp{'2'} ? $temp{'2'} : "-");
	print SNP "\n";
}

close SNP;