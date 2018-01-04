#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;

$image = GD::Image->newFromPng(shift @ARGV);
binmode STDOUT;
print $image->gif;
