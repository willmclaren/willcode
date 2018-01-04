#!/usr/bin/perl

$index_col = 0;
$delim = "\t";
$blank = "";

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	
	if($arg =~ /c/i) {
		$index_col = shift @ARGV;
		$index_col--;
	}
	
	if($arg =~ /b/i) {
		$add_blanks = 1;
	}
	
	if($arg =~ /v/i) {
		$blank = shift @ARGV;
	}
	
	if($arg =~ /d/i) {
		$delim = shift @ARGV;
	}
}


$first = 1;

#open OUT, ">debug";

foreach $file(@ARGV) {
	open IN, $file;
	
	while(<IN>) {
		chomp;
		
		@data = split /$delim/, $_;
		
		@line = ();
		
		for $i(0..$#data) {
			$index = $data[$i] if $i == $index_col;
			
			push @line, $data[$i] unless $i == $index_col;
		}
		
		
		$all{$index} .= $delim;
		$all{$index} .= (join $delim, @line);
		
		push @order, $index if $first;
	}
	
	$first = 0;
	
	close IN;
	
	# add blanks
	if($add_blanks) {
	
		#print OUT "Adding blanks to $file\n";
		
		$max = 0;
		
		# find max no. cols
		foreach $index(keys %all) {
			$count = 0;
			while($all{$index} =~ m/$delim/g) { $count++; }
			
			$max = $count if $count > $max;
		}
		
		#print OUT "Found a max col count of $max\n";
		
		# now add extra cols
		foreach $index(keys %all) {
			$count = 0;
			while($all{$index} =~ m/$delim/g) { $count++; }
			
			for $i(1..($max - $count)) {
				$all{$index} .= $delim.$blank;
			}
		}
	}
}

foreach $index(@order) {
	print $index.$all{$index}."\n";
}