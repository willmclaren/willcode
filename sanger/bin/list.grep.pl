#!/usr/bin/perl

%args_with_vals = (
	'c' => 1,
	'd' => 1,
);

while($ARGV[0] =~ /^\-.+/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	$list{(split /\t/, $_)[0]} = 1;
}

close IN;


$col = ($args{'c'} ? $args{'c'} : 1);

if($col =~ /\,/) {
	@cols = split /\,/, $args{'c'};
}

elsif($col =~ /\+/) {
	@cols = split /\+/, $args{'c'};
	$and = 1;
}

else {
	$cols[0] = $col;
}

for $i(0..$#cols) {
	$cols[$i]--;
}


$delim = ($args{'d'} ? $args{'d'} : "\t");

while(<>) {
	chomp;

	$match = 0;
	
	foreach $col(@cols) {
		$match++ if $list{(split /$delim/, $_)[$col]};
	}
	
	$match = 0 if ($and && ($match != (scalar @cols)));
	
	if($args{'v'}) {
		print "$_\n" unless $match;
	}
	
	else {
		print "$_\n" if $match;
	}
}