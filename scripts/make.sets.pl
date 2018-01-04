#!/usr/bin/perl

%commands = (
	'AND' => 1,
	'and' => 1,
	'NOT' => 1,
	'not' => 1,
	'OR' => 1,
	'or' => 1,
);


# guess this is the first data file
$arg = shift @ARGV;
open IN, $arg or die "Could not open file $arg\n";

while(<IN>) {
	chomp;

	$have{$_}++;
}

close IN;
	
# deal with arguments
while($arg = shift @ARGV) {	
	if($commands{$arg}) {
		$rule = $arg;
		
		$file = shift @ARGV;
		
		open IN, $file or die "You didn't specify a file, or could not open file $file\n";
		
		while(<IN>) {
			chomp;
			
			if($rule =~ /not/i) {
				$have{$_}++ if $have{$_};
			}
			
			else {
				$have{$_}++;
			}
		}
		
		close IN;
		
		# find the max count
		$max = (sort {$a <=> $b} values %have)[-1];
		
		foreach $item(keys %have) {
			if($rule =~ /and/i) {
				delete $have{$item} unless $have{$item} == $max || $max == 1;
			}
			
			elsif($rule =~ /not/i) {
				delete $have{$item} if $have{$item} == $max;
			}
		}
	}
}

foreach $item(keys %have) {
	print $item."\n";
}