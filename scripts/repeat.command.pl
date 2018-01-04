#!/usr/bin/perl

# this variable is 0 by default - when set to 1 it tells the script
# that we don't want to manually input values using STDIN
$list = 0;

# a list of command line arguments / flags that are followed by a value
%args_with_vals = (
	'l' => 1,
	'a' => 1,
	'b' => 1,
	'c' => 1,
	'd' => 1,
	'e' => 1,
	'f' => 1,
	'g' => 1,
	'fill' => 1,
);

@letters = qw/a b c d e f g h i j k/;

# process the flags
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	# get the next element from the array if this flag is meant to be followed by a value
	$val = ($args_with_vals{$arg} ? shift @ARGV : 1);
	
	# special case for -l - this arguments specifies a file containing input variables to be used
	if($arg =~ /^l/) {
		open IN, $val or die "Could not read from list file $val\n";
		while(<IN>) {
			chomp;
			
			# each set of values is stored as a whitespace-delimited string in the array @rpts
			push @rpts, $_;
			
			$list = 1;
		}
		close IN;
	}
	
	else {
		$args{$arg} = $val;
	}
}

# go through the variables e.g. aaa, bbb to see if any have been specified on the command line
foreach $letter(@letters) {
	next unless $args{$letter};
	
	$n = 0;
	
	# deal with e.g. 1-10,12,14-17
	foreach $val(split /\,/, $args{$letter}) {
		@nnn = split /\-/, $val;
		
		for $a($nnn[0]..$nnn[-1]) {
			$rpts[$n] .= " $a";
			$rpts[$n] =~ s/^\s+//g;
			$n++;
		}
	}
	
	$list = 1;
}

# the rest of @ARGV is then assumed to be the command to be run
$command = join " ", @ARGV;

# tell the user what we're assuming the command to be (debug)
print "Command to be run:\n$command\n\n";

# look at the command to see which variable names appear in it
foreach $letter(@letters) {
	$var = $letter.$letter.$letter;
	
	# record which variable names we need to use
	$vars{$var} = 1 if $command =~ /$var/;
}

# set up a loop to go through each of the sets/repeats
JOB: while(1) {

	if($list) {
		# shift off the next set of values; if none left, exit the loop
		@args = split /\s+/, shift @rpts or last JOB;
		
		# for each of the variables we are going to use, set the values to be used in this repeat in the %vals hash
		foreach $var(sort keys %vars) {
			$vals{$var} = (scalar @args ? shift @args : $var);
		}
	}
	
	# enter values manually via STDIN
	# NB user has to manually CTRL-C out of the script in this method
	else {
		foreach $var(sort keys %vars) {
			print "Value for $var: ";
			$vals{$var} = <STDIN>;
			chomp $vals{$var};
		}
	}
	
	# copy the command string so we can sed it
	$ex = $command;
	
	# do the sed-ing substitution for each variable
	foreach $var(keys %vals) {
		if($args{'fill'} && $vals{$var} =~ /\d+/) {
			$v = $vals{$var};
			
			while(length($v) < $args{'fill'}) {
				$v = "0".$v;
			}
			
			$vals{$var} = $v;
		}
	
		$ex =~ s/$var/$vals{$var}/g;
	}
	
	# print out the command we're about to run
	print "$ex\n";
	print "Executing command...";
	
	# run the command using the fancy ` thing - allows us to get back the output directly from the command
	$output = `$ex`;
	
	# confirm it finished and print the output (if there was any)
	print "done\n\n".($output ? "Output:\n$output\n" : "");
}
