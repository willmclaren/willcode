#!/usr/bin/perl

%args_with_vals = (
	's' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$s = "chimp";
$s = $args{'s'} if $args{'s'};

while(<>) {
	if($done) {
		print;
	}
	
	else {
		if(($s eq "chimp") || ($_ =~ /^$s\s+/)) {
			chomp;
			
			@data = split /\s+/, $_;
			
			print shift @data;
			
			for(1..5) { print "\t".(shift @data); }
			
			while(@data) {
				$a = shift @data;
				$b = shift @data;
				
				if($a ne $b) {
					print "\t0 0";
				}
				
				else {
					print "\t$a $b";
				}
			}
			
			print "\n";
			
			$done = 1 unless $s eq "chimp";
		}
		
		else {
			print;
		}
	}
}