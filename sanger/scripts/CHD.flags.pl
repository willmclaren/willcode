#!/usr/bin/perl

#!/usr/bin/perl

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$stem = shift @ARGV;


foreach $type('freq', 'hwe', 'missing','diff') {
	if(open IN, "$stem\.flag\.$type") {
		while(<IN>) {
			chomp;
			
			$flag{$_}{substr("\U$type",0,1)} = 1;
		}
		close IN;
	}
}

open OUT, ">$stem\.flag.markers";

foreach $snp(keys %flag) {
	print OUT "$snp\t".(join ",", sort keys %{$flag{$snp}});
	print OUT "\n";
}

close OUT;


%flag = ();


foreach $type('missing','gender') {
	if(open IN, "$stem\.samples\.flag\.$type") {
		while(<IN>) {
			chomp;
			
			$flag{$_}{substr("\U$type",0,1)} = 1;
		}
		close IN;
	}
}


open OUT, ">$stem\.flag.samples";

foreach $snp(keys %flag) {
	print OUT "$snp\t".(join ",", sort keys %{$flag{$snp}});
	print OUT "\n";
}

close OUT;
