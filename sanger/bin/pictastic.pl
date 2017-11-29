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

@cols = qw/all hets chb jpt yri q/;

debug("Reading data file");

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data == 1) {
		push @data, '1';
		push @data, '1';
	}
	
	$snp = shift @data;
	
	foreach $col(@cols) {
		$data{$snp_info{$snp}{'chr'}}{$snp_info{$snp}{'pos'}}{$col} = shift @data;
	}
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
$image_width = 38;
$chrom_width = 6;
$x_off = 5;


# ITERATE THROUGH CHROMS
########################

debug("Plotting chromosomes");

open DEBUG, ">debug";

for $chr(1..22,'X','Y') { #sort {$a <=> $b} keys %length) {
	$length = sprintf("%.0f", ($length{$chr} / $length{1}) * $max_chrom_height);
	
	if($chr !~ /\d/) {
		next unless $args{'x'};
	}
	
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
	
	
	
	$im->filledRectangle($x_off + $chrom_width + 1, 1, $x_off + $chrom_width + 11, $length - 1, $lightred);
	$im->filledRectangle($x_off + $chrom_width + 12, 1, $x_off + $chrom_width + 23, $length - 1, $vlightgrey);
	
	foreach $pos(keys %{$data{$chr}}) {
		$snp = $snps_by_chrom{$chr}{$pos};
		
		$y = sprintf("%.0f", ($pos / $length{$chr}) * $length);
		
		if($data{$chr}{$pos}{'chb'} == 1 || $data{$chr}{$pos}{'jpt'} == 1 || $data{$chr}{$pos}{'yri'} == 1) {
			$x1 = $x_off + $chrom_width + 13;
			$x2 = $x1 + 5;
			
			$c = $grey;
			
			$im->line($x1, $y, $x2, $y-3, $c);
			$im->line($x1, $y, $x2, $y+3, $c);
			$im->line($x2, $y-3, $x2, $y+3, $c);
			$im->fillToBorder($x2-3,$y,$c,$c);
		
# 			$x1 = $x_off + 1;
# 			$x2 = $x1 + 4;
# 			
# 			$im->line($x1, $y, $x2, $y, $blue);#($data{$chr}{$pos}{'chb'} > 1 ? $green : ($data{$chr}{$pos}{'jpt'} > 1 ? $yellow : $purple)));
		}
	}
	
	foreach $pos(keys %{$data{$chr}}) {
		$snp = $snps_by_chrom{$chr}{$pos};
		
		$y = sprintf("%.0f", ($pos / $length{$chr}) * $length);
		
		# all
		if($data{$chr}{$pos}{'all'}) {
			$x1 = $x_off + 1;
			$x2 = $x1 + $chrom_width - 1;
			
			$im->line($x1, $y, $x2, $y, $grey);
		}
		
		# hets / homs
		if($data{$chr}{$pos}{'hets'} == 1) {
			$x1 = $x_off + $chrom_width + 2;
			$x2 = $x1 + 9;
			
			$col = $im->colorAllocate(2 * $data{$chr}{$pos}{'q'} * 200, 2 * $data{$chr}{$pos}{'q'} * 200, 255);
			
			$im->line($x1, $y, $x2, $y, ($data{$chr}{$pos}{'q'} < 0.1 ? $red : $darkgrey));#$col);
			
			debug("$chr:$pos $data{$chr}{$pos}{'q'} ".($data{$chr}{$pos}{'q'} < 0.1 ? "red" : "grey")." $y");
		}
		
# 		if($data{$chr}{$pos}{'hets'} == 1.1) {
# 			$x1 = $chrom_width + 2;
# 			$x2 = $x1 + 5;
# 			
# 			$im->line($x1, $y, $x2, $y, ($data{$chr}{$pos}{'q'} < 0.1 ? $red : $lightred));
# 		}
		
		if(($data{$chr}{$pos}{'chb'} > 1) || ($data{$chr}{$pos}{'jpt'} > 1) || ($data{$chr}{$pos}{'yri'} > 1)) {
		
			$x1 = $x_off + $chrom_width + 13;
			$x2 = $x1 + 9;
			
# 			$poly = new GD::Polygon;
# 			$poly->addPt($x1,$y);
# 			$poly->addPt($x2,$y-3);
# 			$poly->addPt($x2,$y+3);
# 			$im->fillPoly($poly, ($data{$chr}{$pos}{'chb'} > 1 ? $green : ($data{$chr}{$pos}{'jpt'} > 1 ? $yellow : $purple)));
			
# 			$im->line($x1, $y, $x2, $y-3, ($data{$chr}{$pos}{'chb'} > 1 ? $green : ($data{$chr}{$pos}{'jpt'} > 1 ? $yellow : $purple)));
# 			$im->line($x1, $y, $x2, $y+3, ($data{$chr}{$pos}{'chb'} > 1 ? $green : ($data{$chr}{$pos}{'jpt'} > 1 ? $yellow : $purple)));
# 			$im->line($x2, $y-3, $x2, $y+3, ($data{$chr}{$pos}{'chb'} > 1 ? $green : ($data{$chr}{$pos}{'jpt'} > 1 ? $yellow : $purple)));
			
			if($args{'homs'}) {
				$im->line($x1, $y, $x2, $y, $blue);#$col);
				#debug("$chr:$pos $data{$chr}{$pos}{'q'} ".($data{$chr}{$pos}{'q'} < 0.1 ? "" : "grey")." $y");
			}
			
			else {
				next if (($args{'nc'}) && ($data{$chr}{$pos}{'chb'} > 1) && ($data{$chr}{$pos}{'jpt'} < 2) && ($data{$chr}{$pos}{'yri'} < 2));
				next if (($args{'nj'}) && ($data{$chr}{$pos}{'chb'} < 2) && ($data{$chr}{$pos}{'jpt'} > 1) && ($data{$chr}{$pos}{'yri'} < 2));
				next if (($args{'ny'}) && ($data{$chr}{$pos}{'chb'} < 2) && ($data{$chr}{$pos}{'jpt'} < 2) && ($data{$chr}{$pos}{'yri'} > 1));
			
				$c = ((($data{$chr}{$pos}{'chb'} > 1) && (!$args{'nc'})) ? $green : ((($data{$chr}{$pos}{'jpt'} > 1) && (!$args{'nj'})) ? $yellow : $purple));
				$im->line($x1, $y, $x2, $y-4, $c);
				$im->line($x1, $y, $x2, $y+4, $c);
				$im->line($x2, $y-4, $x2, $y+4, $c);
				$im->fillToBorder($x2-4,$y,$c,$c);
			}
		}
		
	}
	
	
	# draw the side lines of the chrom
	$im->rectangle($x_off,1,$x_off + $chrom_width,$length-1,$black);
	
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
		
		$link = (split /\//, $args{'o'}.".ruler.png")[-1];
		
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
						img({-src => $link}),
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
	
	$link = (split /\//, $args{'o'}.".chr$chr.png")[-1];
	
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
					img({-src => $link}),
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