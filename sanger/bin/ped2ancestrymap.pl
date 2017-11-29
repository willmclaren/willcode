#!/usr/bin/perl

%args_with_vals = (
	's' => 1,
);

%args = (
	's' => '/lustre/work1/sanger/wm2/Affy/data/snp.info',
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# GET SNP INFO
##############

if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	#debug("Loading SNP info from $args{'s'}");
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		if(scalar @data == 3) {
			($snp, $chrom, $pos) = @data;
		}
		
		else {
			($chrom, $snp, $crap, $pos) = @data;
		}
		
		push @snps, $snp;
	}
	
	close IN;
}



while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	for(1..5) {
		shift @data;
	}
	
	foreach $snp(@snps) {
		$a = shift @data;
		$b = shift @data;
		
		if($a ne $b) {
			$out = 1;
		}
		
		elsif("$a$b" =~ /N|0/i) {
			$out = -1;
		}
		
		elsif($seen{$snp}) {
			if($seen{$snp}{$a}) {
				$out = 0;
			}
		
			else {
				$out = 2;
			}
		}
		
		else {
			$out = 0;
			$seen{$snp}{$a} = 1;
		}
	
		print "$snp\t$sample\t$out\n" if $out >= 0;
	}
}



sub isHet() {
	my $g = shift;
	
	return (substr($g,0,1) eq substr($g,1,1) ? 0 : 1);
}
