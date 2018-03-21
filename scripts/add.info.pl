#!/usr/bin/perl

%args_with_vals = (
	'c' => 1,
	'd' => 1,
);

$args{'d'} = "\t";

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$col = (defined($args{'c'}) ? $args{'c'} : 1);
$col--;

open IN, shift @ARGV;

while(<IN>) {
	chomp;

	@data = split /\t/, $_;
	
	$index = shift @data;
	
	$info{$index} = join "\t", @data;
}

close IN;


while(<>) {
	chomp;
	
	if($args{'b'}) {
		print $info{(split /$args{'d'}/, $_)[$col]}.$args{'d'}.$_."\n";
	}
	else {
		print $_.$args{'d'}.$info{(split /$args{'d'}/, $_)[$col]}."\n" ;
	}
}
