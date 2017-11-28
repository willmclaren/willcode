#!/usr/bin/env perl

if($ARGV[0] =~ /^\d/) {
  $num = shift @ARGV;
}

else {
  $num = 0.1;
}

while(<>) { print if rand() < $num;}
