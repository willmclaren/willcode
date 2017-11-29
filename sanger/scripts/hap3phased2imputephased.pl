#!/usr/bin/perl

%args_with_vals = (
	'o' => 1,
);

$args{'o'} = "imputephased";

# process the flags
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	# get the next element from the array if this flag is meant to be followed by a value
	$val = ($args_with_vals{$arg} ? shift @ARGV : 1);
	
	$args{$arg} = $val;
}

open PHASED, ">".$args{'o'}."_phased.txt";
open LEGEND, ">".$args{'o'}."_legend.txt";

# header required in legend file
print LEGEND "rs position a0 a1\n";


while(<>) {
	next if /^rsID/;
	
	chomp;
	
	@data = split /\s+/, $_;
	
	$snp = shift @data;
	$pos = shift @data;
	
	%key = ();
	$first = 1;
	
	while(@data) {
		$a = shift @data;
		
		if(!(defined $key{$a})) {
			if(scalar keys %key) {
				$key{$a} = 1;
			}
			
			else {
				$key{$a} = 0;
			}
		}
		
		print PHASED ($first ? "" : " ");
		print PHASED $key{$a};
		$first = 0;
	}
	
	print PHASED "\n";
	
	print LEGEND "$snp $pos ";
	print LEGEND (join " ", sort {$key{$a} <=> $key{$b}} keys %key);
	
	if(scalar keys %key < 2) {
		print LEGEND " -";
	}
	
	print LEGEND "\n";
}