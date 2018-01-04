#!/usr/bin/perl

%args_with_vals = (
	'd' => 1,
);

$args{'d'} = "\t";

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

foreach $file(@ARGV) {
	push @handles, newopen($file);
}


LOOP: while(1) {
	$first = 1;

	foreach $file(@handles) {
		$line = <$file>;
		
		#print "\t".substr($line, 0, 10);
		
		unless($first) {
			$line =~ s/^.+?$args{'d'}/$args{'d'}/;
		}
		
		chomp $line;
		
		print $line;
		#print "\t".(split /\t/, $line)[-1];
		
		$first = 0;
	}
	
	last LOOP if eof($handles[-1]);
	
	print "\n";
}

print "\n";


sub newopen {
	my $path = shift;
	local *FH;
	open(FH, $path) or return undef;
	return *FH;
}