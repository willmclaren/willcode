#!/usr/bin/perl

%args = ( 'd' => "\t" );

while($ARGV[0] =~ /\-+([a-zA-Z]+)/) {
  shift;
  $args{$1} = shift;
}

$col_a = shift;
$col_b = shift;

$col_a--;
$col_b--;

while(<>) {
	chomp;
	
	@data = split /$args{d}/, $_;
	
	$temp = $data[$col_a];
	$data[$col_a] = $data[$col_b];
	$data[$col_b] = $temp;
	
	print (join $args{d}, @data);
	print "\n";
}
