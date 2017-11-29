#!/usr/bin/perl

$index_col = 0;
$delim = "\t";

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	
	if($arg =~ /c/i) {
		$index_col = shift @ARGV;
		$index_col--;
	}
	
	if($arg =~ /d/i) {
		$delim = shift @ARGV;
	}
}

while(<>) {
	chomp;
	
	@data = split /$delim/, $_;
	
	if($data[$index_col] ne $prev) {
		close OUT;
		open OUT, ">>$data[$index_col].split";
	}
	
	print OUT $_."\n";
	
	$prev = $data[$index_col];
}