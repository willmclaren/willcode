#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;

$img_a = shift @ARGV;
$img_b = shift @ARGV;
$out = shift @ARGV;

$a = GD::Image->new($img_a);
$b = GD::Image->new($img_b);

$c = GD::Image->new($a->width,($a->height + $b->height));

$c->copy($a, 0, 0, 0, 0, $a->width, $a->height);
$c->copy($b, 0, $a->height, 0, 0, $b->width, $b->height);


open IM, ">".($out ? $out : "merged.png");
binmode IM;
print IM $c->png;
close IM;