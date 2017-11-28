#!/usr/bin/env perl

use strict;
use warnings;

use FileHandle;
use Scalar::Util qw(looks_like_number);

my $f1 = FileHandle->new();
my $f2 = FileHandle->new();

$f1->open(-B $ARGV[0] ? "gzip -dc ".shift." | " : shift);
$f2->open(-B $ARGV[0] ? "gzip -dc ".shift." | " : shift);

my $ln = 0;
my @h;

LINE: while((my $l1 = $f1->getline) && (my $l2 = $f2->getline)) {


  if($l1 =~ /^\#U/) {
    @h = split("\t", $l1);
  }

  $ln++;

  next if $l1 eq $l2;

  # header line
  if($l1 =~ /^\#/ && $l2 =~ /^\#/) {
    printf("F1 L %i: %sF2 L %i: %s\n", $ln, $l1, $ln, $l2) unless $l1 eq $l2;
    next;
  }

  else {
    my @l1 = split("\t", $l1);
    my @l2 = split("\t", $l2);

    unless(@l1 == @l2) {
      $DB::single = 1;
      printf("F1 L %i cols: %i\nF2 L %i cols: %i\n\n", $ln, scalar @l1, $ln, scalar @l2);
      next;
    }

    COL: for my $i(0..$#l1) {
      my $i1 = $l1[$i];
      my $i2 = $l2[$i];

      # comma-sep list
      if($i1 =~ /\,/) {

        if(join(",", sort split(",", $i1)) ne join(",", sort split(",", $i2))) {
          $DB::single = 1;
          printf("F1 L %i col %i list: %s\nF2 L %i col %i list: %s\n\n", $ln, $i+1, $i1, $ln, $i+1, $i2);
        }
        else {
          next COL;
        }
      }

      # number
      elsif(looks_like_number($i1) && looks_like_number($i2)) {
        if (
          sprintf("%.5g", $i1) == sprintf("%.5g", $i2) ||
          sprintf("%.4g", $i1) == sprintf("%.4g", $i2) ||
          sprintf("%.3g", $i1) == sprintf("%.3g", $i2) ||
          sprintf("%.2g", $i1) == sprintf("%.2g", $i2) ||
          sprintf("%.4f", $i1) == sprintf("%.4f", $i2)
        ) {
          next COL;
        }
        else {
          $DB::single = 1;
          printf("F1 L %i col %i num: %s\nF2 L %i col %i num: %s\n\n", $ln, $i+1, $i1, $ln, $i+1, $i2);
        }
      }

      elsif($i1 ne $i2) {
        $DB::single = 1;
        printf("F1 L %i col %i: %s\nF2 L %i col %i: %s\n\n", $ln, $i+1, $i1, $ln, $i+1, $i2);
      }
    }
  }
}
