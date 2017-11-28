#!/usr/bin/env perl

open IN, shift;
my $h = <IN>;
@h = split("\t", $h);
close IN;

while(<>) {
  chomp;
  my @d = split("\t", $_);

  for my $h(@h) {
    print "$h\t".(@d ? shift @d : "---")."\n";
  }

  print "\n";
}
