#!/usr/bin/perl

$delim = "\t";
%args_with_vals = (
	'c' => 1,
	'v' => 1,
	'd' => 1,
	'g' => 1,
	'l' => 1,
	'le' => 1,
	'ge' => 1,
	'b' => 1,
);

# variable to determine and/or of column assessment (and = 1, or = 0)
$and = 1;

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$val = shift @ARGV if $args_with_vals{$arg};
	
	if($arg =~ /^c/i) {
		$column = $val;
		$and-- if $column =~ /\,/;
		@cols = split /\+|\,/, $column;
	}
	
	elsif($arg =~ /^v/i) {
		$string = $val;
	}
	
	elsif($arg =~ /^d/i) {
		$delim = $val;
	}
	
	elsif($arg =~ /^i/i) {
		$case_insensitive = 1;
	}
	
	elsif($arg =~ /^e/i) {
		$exact_match = 1;
	}
	
	elsif($arg =~ /^b/i) {
		@between = split /\,/, $val;
	}
	
	elsif($arg =~ /^n/i) {
		$invert_match = 1;
	}
	
	elsif($arg =~ /^h/i) {
		$test_length = 1;
	}
	
	elsif($arg =~ /^g/i) {
		if($arg =~ /e/i) {
			$gte = $val;
		}
		
		else {
			$gt = $val;
		}
	}
	
	elsif($arg =~ /^l/i) {
		if($arg =~ /e/i) {
			$lte = $val;
		}
		
		else {
			$lt = $val;
		}
	}
	
	elsif($arg =~ /^p/i) {
		$args{'p'} = 1;
	}
	
	elsif($arg =~ /^w/i) {
		$within = 1;
	}
}

#die "No input file specified\n" unless @ARGV;

$string = "\U$string" if $case_insensitive;

while(<>) {
	if($args{'h'}) {
		print;
		delete $args{'h'};
		next;
	}

	chomp;
	
	$_ = "\U$_" if $case_insensitive;
	
	@data = split /$delim/, $_;
	
	$print = 0;
	
	foreach $column(@cols) {
		
		next if $column > scalar @data;
		
		$thing = $data[($column - 1)];
		$thing = length($thing) if $test_length;
		
		if($exact_match) {
			$print++ if "$thing" eq "$string";
		}
		
		#elsif($invert_match) {
		#	print "$_\n" unless $thing =~ /$invert_match/;
		#}
		
		elsif(defined $gte) {
			$print++ if $thing >= $gte && $thing =~ /\d/;
		}
		
		elsif(defined $lte) {
			$print++ if $thing <= $lte && $thing =~ /\d/;
		}
		
		elsif(defined $gt) {
			$print++ if $thing > $gt && $thing =~ /\d/;
		}
		
		elsif(defined $lt) {
			$print++ if $thing < $lt && $thing =~ /\d/;
		}
		
		elsif(scalar @between) {
			$print++ if (($thing >= $between[0]) && ($thing <= $between[1]) && ($thing =~ /\d/));
		}
		
		else {
			foreach $s(split /\,/, $string) {
				if($within) {
					$s = $data[($s-1)];
				}
			
				if($thing =~ /$s/) {
					$print++;
					last;
				}
			}
		}
	}
	
	$ok = 0;
	if($and) {
		$ok = 1 if scalar @cols == $print;
	}
	else {
		$ok = 1 if $print > 0;
	}
	$ok = ($ok ? 0 : 1) if $invert_match;
	
	if($args{'p'}) {
		$matched++ if $ok;
		$total++;
	}
	
	else {
		print "$_\n" if $ok;
	}
}

if($args{'p'}) {
	$perc = ($total ? 100 * ($matched / $total) : 0);
	
	print "$matched\t$total\t$perc\n";
}