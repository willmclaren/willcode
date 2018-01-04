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
	'o' => 'pictastic',
	'h' => '900',
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# GET SNP INFO
##############

if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	debug("Loading SNP info from $args{'s'}");
	
	while(<IN>) {
		chomp;
		
		($snp, $chrom, $pos) = split /\s+/, $_;
		$snp_info{$snp}{'chr'} = $chrom;
		$snp_info{$snp}{'pos'} = $pos;
		
		$snps_by_chrom{$chrom}{$pos} = $snp;
	}
	
	close IN;
}


# LOAD DATA FILE
################

debug("Reading data file");

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	push @{$data{$snp_info{$data[-2]}{'chr'}}{$data[2]}}, $snp_info{$data[-2]}{'pos'}." ".$snp_info{$data[-1]}{'pos'};
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
$image_width = 33;
$chrom_width = 6;
$x_off = 4;


# ITERATE THROUGH CHROMS
########################

debug("Plotting chromosomes");

open DEBUG, ">debug";

for $chr(1..22) {
	$length = sprintf("%.0f", ($length{$chr} / $length{1}) * $max_chrom_height);
	
	#print "Plotting chromosome $chr, length $length\n";
	
	# start a GD object for this chromosome
	$im = new GD::Image($image_width,$length);
	
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
	
# 	$im->setAntiAliased($yellow);
# 	$im->setAntiAliased($purple);
# 	$im->setAntiAliased($green);
	
	
	
	$im->filledRectangle($x_off + 1, 1, $x_off + 11, $length - 1, $lightred);
	$im->filledRectangle($x_off + 12, 1, $x_off + 23, $length - 1, $lightblue);
	$im->rectangle($x_off + 1, 1, $x_off + 23, $length -1, $black);
	
	foreach $copy(keys %{$data{$chr}}) {
		foreach $block(@{$data{$chr}{$copy}}) {
			($pos_a, $pos_b) = split /\s+/, $block;
			
			$y1 = sprintf("%.0f", ($pos_a / $length{$chr}) * $length);
			$y2 = sprintf("%.0f", ($pos_b / $length{$chr}) * $length);
			
			$im->filledRectangle($x_off + ($copy eq 'A' ? 1 : 12), $y1, $x_off + ($copy eq 'A' ? 11 : 23), $y2, ($copy eq 'A' ? $red : $blue));
		}
	}
	
	
	# draw the side lines of the chrom
	#$im->rectangle($x_off,1,$x_off + $chrom_width,$length-1,$black);
	
	if($chr == 1) {
		$gd = new GD::Image(30,$length);
		
		$white = $gd->colorAllocate(255,255,255);
		$black = $gd->colorAllocate(0,0,0);
		$grey = $gd->colorAllocate(200,200,200);
		$darkgrey = $gd->colorAllocate(150,150,150);
	
		# add ruler
		$units = 1000000;
		$y = 0;
		
		while($y < $length{$chr}) {
			
			#print "$x $scaled_x\n";
			$y += $units;
			#next unless $x > $sorted_pos[0];
			
			$scaled_y = sprintf("%.0f", ($y / $length{$chr}) * $length);
			
			$num = $y;
			$num_zeroes = $units =~ tr/0/0/;
			$count = 0;
			
			while($count++ < $num_zeroes) {
				$num =~ s/0$//;
			}
			
			if($num =~ /0$/) {
				$label = ($y / $units);#."MB";
				$gd->string(gdGiantFont, 1, $scaled_y-16, $label, ($num =~ /5$/ ? $darkgrey : $black));
				$gd->dashedLine(0, $scaled_y, 50, $scaled_y, ($num =~ /5$/ ? $darkgrey : $black));
			}
			
# 			else {
# # 				if($scale <= 30000) {
# # 					$label = ($y / $units)."MB";
# # 					$gd->string(gdTinyFont,2,$scaled_y+2,$label,$grey);
# # 				}
# 				
# 				$gd->dashedLine(5, $scaled_y, 10, $scaled_y, $grey);
# 			}
		}
		
		open IM, ">".$args{'o'}.".ruler.png";
		binmode IM;
		print IM $gd->png;
		close IM;
		
		push @row,
			table(
				{-border => 0, -cellpadding => 0, -cellspacing => 0, -height => "100%"},
				Tr(
					td(
						{-align => "center", -style => "font-family:sans-serif;font-size:18px;"},
						"Mb",
					),
				),
				Tr(
					{-valign => "top"},
					td(
						{-height => "100%"},
						img({-src => $args{'o'}.".ruler.png"}),
					),
				),
			);
	}
	
	# add ruler
	$units = 1000000;
	$y = 0;
	
	while($y < $length{$chr}) {
		
		#print "$x $scaled_x\n";
		$y += $units;
		#next unless $x > $sorted_pos[0];
		
		$scaled_y = sprintf("%.0f", ($y / $length{$chr}) * $length);
		
		$num = $y;
		$num_zeroes = $units =~ tr/0/0/;
		$count = 0;
		
		while($count++ < $num_zeroes) {
			$num =~ s/0$//;
		}
		
		if($num =~ /5$|0$/) {
			$im->line(($num =~ /5$/ ? 1 : 0), $scaled_y, 4, $scaled_y, ($num =~ /5$/ ? $darkgrey : $black));
		}
		
		elsif($args{'h'} > 1000) {
# 			if($scale <= 30000) {
# 				$label = ($y / $units)."MB";
# 				$gd->string(gdTinyFont,2,$scaled_y+2,$label,$grey);
# 			}
			
			$im->line(3, $scaled_y, 4, $scaled_y, $darkgrey);
		}
	}
	
	# write out the image file
	open IM, ">".$args{'o'}.".chr$chr.png";
	binmode IM;
	print IM $im->png;
	close IM;
	
	push @row,
		table(
			{-border => 0, -cellpadding => 0, -cellspacing => 0, -height => "100%"},
			Tr(
				td(
					{-align => "center", -style => "font-family:sans-serif;font-size:18px;"},
					$chr,
				),
			),
			Tr(
				{-valign => "top"},
				td(
					{-height => "100%"},
					img({-src => $args{'o'}.".chr$chr.png"}),
				),
			),
		);
}

debug("Writing HTML to $args{'o'}\.html");

open OUT, ">$args{'o'}\.html";

print OUT
	start_html(
		-title => (split /\//, $args{'o'})[-1],
	),
	table(
		{-border => 0, -cellpadding => 0, -cellspacing => 0},
		Tr(
			{-valign => "top"},
			td(
				{-height => "100%"},
				\@row,
			),
		),
	),
	end_html;
	
close OUT;




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