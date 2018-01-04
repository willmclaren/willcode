#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;
use GD::Polygon;
use CGI qw/:standard/;
use CGI::Pretty;

%args_with_vals = (
	's' => 1,
	'o' => 1,
	'h' => 1,
);

%args = (
	's' => '/lustre/work1/sanger/wm2/Affy/data/snp.info',
	'o' => '/nfs/team71/psg/wm2/Documents/Plots/test',
	'h' => '900',
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# LOAD DATA FILE
################
debug("Reading data file");

while(<>) {
	chomp;
	
	($chr, $from, $to, $ceu, $chb, $yri) = split /\s+/, $_;
	
	$data{$chr}{$from."_".$to}{'ceu'} = $ceu;
	$data{$chr}{$from."_".$to}{'chb'} = $chb;
	$data{$chr}{$from."_".$to}{'yri'} = $yri;
}


# PRESET VALUES
###############

%length = (
	1 => "247249719",
	2 => "242951149",
	3 => "199501827",
	4 => "191273063",
	5 => "180857866",
	6 => "170899992",
	7 => "158821424",
	8 => "146274826",
	9 => "140273252",
	10 => "135374737",
	11 => "134452384",
	12 => "132349534",
	13 => "114142980",
	14 => "106368585",
	15 => "100338915",
	16 => "88827254",
	17 => "78774742",
	18 => "76117153",
	19 => "63811651",
	20 => "62435964",
	21 => "46944323",
	22 => "49691432",
	'X' => "154913754",
	'Y' => "57772954"
);


$max_chrom_height = $args{'h'};
#$image_width = 38;
$chrom_width = 6;
$x_off = 0;

$gap = 5;

# calculate height and width
$height = $max_chrom_height;
$width = (($args{'x'} ? 25 : 23) * (33 + $gap)) - $gap;

# debug("Creating $width x $height image");
# 
# die "Creating $width x $height image\n";

# create the image
$im = new GD::Image($width,30+$height);

# allocate some colors
$white = $im->colorAllocate(255,255,255);
$black = $im->colorAllocate(0,0,0);
$grey = $im->colorAllocate(200,200,200);
$darkgrey = $im->colorAllocate(150,150,150);
$vlightgrey = $im->colorAllocate(235,235,235);
$blue = $im->colorAllocate(0,0,200);
$lightblue = $im->colorAllocate(230,230,255);
$red = $im->colorAllocate(200,0,0);
$lightred = $im->colorAllocate(255,220,220);
$green = $im->colorAllocate(0,200,0);
$lightgreen = $im->colorAllocate(220,255,220);
$yellow = $im->colorAllocate(236,164,26);
$purple = $im->colorAllocate(195,50,212);


# add labels at the top
for $c(1..22,'X','Y') {
	$x_off += 38;
	
	$im->string(gdGiantFont, $x_off + (length($c) == 1 ? 8 : 4), 0, $c, $black);
}

# add ruler
$units = 1000000;
$y = 0;
$y_off = 20;

$im->string(gdGiantFont, 1, 17, "MB",$black);
$im->string(gdGiantFont, 15, 0, "Chr", $black);
$im->line(0,5,25,22,$black);

while($y < $length{1}) {
	
	#print "$x $scaled_x\n";
	$y += $units;
	#next unless $x > $sorted_pos[0];
	
	$scaled_y = sprintf("%.0f", ($y / $length{1}) * $height) + $y_off;
	
	$num = $y;
	$num_zeroes = $units =~ tr/0/0/;
	$count = 0;
	
	while($count++ < $num_zeroes) {
		$num =~ s/0$//;
	}
	
	if($num =~ /0$/) {
		$label = ($y / $units);#."MB";
		$im->string(gdGiantFont, 1, $scaled_y-16, $label, ($num =~ /5$/ ? $darkgrey : $black));
		$im->dashedLine(0, $scaled_y, 50, $scaled_y, ($num =~ /5$/ ? $darkgrey : $black));
	}
}


$x_off = 0;

# ITERATE THROUGH CHROMS
########################

debug("Plotting chromosomes");

open DEBUG, ">debug";

for $chr(1..22,'X','Y') { #sort {$a <=> $b} keys %length) {
	$length = sprintf("%.0f", ($length{$chr} / $length{1}) * $max_chrom_height);
	
	if($chr !~ /\d/) {
		next unless $args{'x'};
	}
	
	$x_off += 38;
	
	
	$im->filledRectangle($x_off + $chrom_width + 1, $y_off + 1, $x_off + $chrom_width + 11, $y_off + $length - 1, $lightred);
	$im->filledRectangle($x_off + $chrom_width + 12, $y_off + 1, $x_off + $chrom_width + 23, $y_off + $length - 1, $vlightgrey);
	
	
	foreach $pos(keys %{$data{$chr}}) {
		($from, $to) = split /\_/, $pos;
		
		$fromy = sprintf("%.0f", (($from * 1000000) / $length{$chr}) * $length) + $y_off;
		$toy = sprintf("%.0f", (($to * 1000000) / $length{$chr}) * $length) + $y_off;
		
		$toy = (($toy - $y_off) > $length ? $length + $y_off : $toy);
		
		$x1 = $x_off + $chrom_width + 2;
		$x2 = $x1 + 9;
		
		$col = $im->colorAllocate(
			$data{$chr}{$pos}{'ceu'} * 255,
			$data{$chr}{$pos}{'chb'} * 255,
			$data{$chr}{$pos}{'yri'} * 255
		);
		
		$im->filledRectangle($x1, $fromy, $x2, $toy, $col);
		
		#print "Drawing rectangle at $x1,$fromy,$x2,$toy\n";
	}
	
	
	$im->rectangle($x_off,$y_off + 1,$x_off + $chrom_width,$y_off + $length-1,$black);
	
	
	# add ruler
	$units = 1000000;
	$y = 0;
	
	$c = $x_off - 5;
	
	while($y < $length{$chr}) {
		
		#print "$x $scaled_x\n";
		$y += $units;
		#next unless $x > $sorted_pos[0];
		
		$scaled_y = sprintf("%.0f", ($y / $length{$chr}) * $length) + $y_off;
		
		$num = $y;
		$num_zeroes = $units =~ tr/0/0/;
		$count = 0;
		
		while($count++ < $num_zeroes) {
			$num =~ s/0$//;
		}
		
		if($num =~ /5$|0$/) {
			$im->line($c + ($num =~ /5$/ ? 1 : 0), $scaled_y, $c + 4, $scaled_y, ($num =~ /5$/ ? $darkgrey : $black));
		}
		
		elsif($args{'h'} > 1000) {
# 			if($scale <= 30000) {
# 				$label = ($y / $units)."MB";
# 				$gd->string(gdTinyFont,2,$scaled_y+2,$label,$grey);
# 			}
			
			$im->line($c + 3, $scaled_y, $c + 4, $scaled_y, $darkgrey);
		}
	}
	
	# write out the image file
	open IM, ">".$args{'o'}.".png" or die "Could not write to file $args{'o'}\.png\n";
	binmode IM;
	print IM $im->png;
	close IM;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime();
	
	print DEBUG $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
} 


# GET CURRENT DATE AND TIME IN SQL FORMAT
#########################################

sub getTime() {
	my @time = localtime(time());

	# increment the month (Jan = 0)
	$time[4]++;

	# add leading zeroes as required
	for my $i(0..4) {
		$time[$i] = "0".$time[$i] if $time[$i] < 10;
	}

	# put the components together in a string
	my $time =
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}