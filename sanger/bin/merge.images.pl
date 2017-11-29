#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;

$args{'o'} = "merged";
$args{'s'} = 0;

%args_with_vals = (
	'o' => 1,
	's' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$out = $args{'o'}.".png";

$max_w = 0;
$max_h = 0;

$total_w = 0;
$total_h = 0;

while(@ARGV) {
	$img = shift @ARGV;
	$a = GD::Image->new($img);
	
	# max width/height
	$max_w = ($a->width > $max_w ? $a->width : $max_w);
	$max_h = ($a->height > $max_h ? $a->height : $max_h);
	
	$total_w += $a->width;
	$total_h += $a->height;
	
	push @gds, $a;
}

if($args{'s'} > 0) {
	$total_w += ((scalar @gds) - 1) * $args{'s'};
	$total_h += ((scalar @gds) - 1) * $args{'s'};
}

# reverse order of images?
if($args{'r'}) {
	@gds = reverse @gds;
}

# horizontal merging
if($args{'h'}) {
	$c = GD::Image->new($total_w, $max_h);
	$c->colorAllocate(255,255,255);
	
	$prev_x = 0;
	
	foreach $a(@gds) {
		$c->copy($a, $prev_x, 0, 0, 0, $a->width, $a->height);
		
		$prev_x += $a->width;
		$prev_x += $args{'s'};
	}
}

else {
	$c = GD::Image->new($max_w, $total_h);
	$c->colorAllocate(255,255,255);
	
	$prev_y = 0;
	
	foreach $a(@gds) {
		$c->copy($a, 0, $prev_y, 0, 0, $a->width, $a->height);
		
		$prev_y += $a->height;
		$prev_y += $args{'s'};
	}
}


open IM, ">".($out ? $out : "merged.png");
binmode IM;
print IM $c->png;
close IM;