#!/usr/bin/perl

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$active = 1 if $args{'p'};

while(<>) {
	if(!$active) {
		$active = 1 if /BEGIN GENOTYPES/;
	}
	
	else {
		chomp;
		
		last if /END GENOTYPES/;
		
		if($args{'p'}) {
			$s = (split /\s+/, $_)[-1];
		}
		
		else {
			$s = $_;
		}
		
		print "$s\t1\t0\t0\t0\t0";
		
		$a = <>;
		$b = <>;
		
		@a = split /\s+/, $a;
		@b = split /\s+/, $b;
		
		die "Number of genotypes does not match\n" unless scalar @a == scalar @b;
		
		while(@a) {
			print "\t".(shift @a)." ".(shift @b);
		}
		
		print "\n";
	}
}