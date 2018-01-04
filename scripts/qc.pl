#!/usr/bin/perl

my %args_with_vals = (
	'c' => 1,
	't' => 1,
);

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$col = ($args{'c'} ? $args{'c'} : 4);
$col--;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if($args{'g'}) {
		if($data[$col] > $args{'t'}) {
			$data[2] = "NN";
		}
	}
	
	else {
		if($data[$col] < $args{'t'}) {
			$data[2] = "NN";
		}
	}
	
	print (join "\t", @data);
	print "\n";
}