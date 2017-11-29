#!/usr/bin/perl

%args_with_vals = (
	'd' => 1,
);


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$d = ($args{'d'} ? $args{'d'} : "\t");

while(<>) {
	chomp;
	
	@data = split $d, $_;
	
	if($args{'r'}) {
		print (join $d, reverse sort @data);
	}
	
	else {
		print (join $d, sort @data);
	}
	
	print "\n";
}