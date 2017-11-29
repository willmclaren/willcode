#!/usr/bin/perl

$from = shift @ARGV;
$to = shift @ARGV;

$from--;
$to--;

die "FROM and TO columns cannot be the same!\n" if $from == $to;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	#$from = $#data if $from >= (scalar @data);
	
	$insert = $data[$from];
	$data[$from] = "___BADGER___";
	
	$first = 1;
	
	foreach $i(0..(scalar @data)) {
		if($i == $to) {
			print ($first ? "" : "\t");
			print $insert;
			$first = 0;
		}
		
		if($data[$i] ne "___BADGER___") {
			print ($first ? "" : "\t");
			print $data[$i];
		}
		
		$first = 0;
	}
	
	print "\n";
}