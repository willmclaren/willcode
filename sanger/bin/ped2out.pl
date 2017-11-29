#!/usr/bin/perl

%args_with_vals = (
);

while($ARGV[0] =~ /^\-.+/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$id = (length($data[1]) > 1 ? $data[1] : $data[0]);
	
	for(1..6) {
		shift @data;
	}
	
	$num = 0;
	
	print $id;
	
	while(@data) {
		$a = shift @data;
		$b = shift @data;
		
		$geno = $a.$b;
		
		$geno =~ tr/01234/NACGT/ unless $args{'1'};
		
		print "\t$geno";
	}
	
	print "\n";
}