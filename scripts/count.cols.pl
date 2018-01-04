#!/usr/bin/perl

$args{'d'} = "\t";

%args_with_vals = (
	'd' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$delim = $args{'d'};


while(<>) {
	$c = $_;
	$count = $c =~ tr/\t/t/;
	$count++;
	chomp $_;
	print $count.($args{'f'} ? "\t".$_ : "")."\n";
}
