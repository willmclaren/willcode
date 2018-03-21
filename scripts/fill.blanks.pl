#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $config = {
	'delimiter' => "\t",
	'value' => 0,
};

# parse command line
GetOptions(
  $config,

  # displays help message
  'help|h',
  
  # value to enter, default 0
  'value=s',

  # delimiter
  'delimiter=s',
);

my $val = $config->{value};
my $delim = $config->{delimiter};
while(<>) {
	s/$delim($delim|\n)/$delim$val$1/g;
	# s/$delim\n/$delim$val\n/g;
	print;
}