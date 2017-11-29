#!/usr/bin/perl

############################
# RHHmapper v0.01          #
#                          #
# by William McLaren       #
# last modified 05/03/2008 #
############################



# LIBRARY DECLARATIONS
######################

# line added by me as my libraries are in a non-standard place
use lib '/nfs/team71/psg/wm2/Perl';

# GD libraries for image creating
use GD;
use GD::Polygon;



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




# DEAL WITH COMMAND-LINE ARGUMENTS
##################################

# arguments that should have a value following them
%args_with_vals = (
	's' => 1,
	'o' => 1,
	'h' => 1,
	'l' => 1,
	'f' => 1,
);

# defaults on my system
%args = (
	's' => '/lustre/work1/sanger/wm2/Affy/data/snp.info',
	'o' => 'RHHmapper',
	'h' => '900',
);


# usage
$usage =
	"RHHmapper v0.1\n\nERROR: Not enough arguments supplied\n\n".
	"Usage: RHHmapper.pl [arguments] data_file\n\n".
	"List of possible arguments:\n".
	"\t-s - specify a map file [default: $args{'s'}]\n".
	"\t-o - specify an output stem [default: \"RHHmapper\"]\n".
	"\t-f - specify a file containing a list of samples to be plotted [default: not used]\n".
	"\t-l - give a comma-separated list of sample IDs to be plotted [default: not used]\n".
	"\t-h - change the height of the images generated [default: $args{'d'}\n".
	"\nBy default RHHmapper will generate a plot for each sample in the data file\n";
	
if(scalar @ARGV < 1) {
	die $usage;
}


# process arguments from command line
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# comma separated sample list
if($args{'l'}) {
	@inclist = split /\,/, $args{'l'};
}

# sample list in file
if($args{'f'}) {
	open IN, $args{'f'} or die "ERROR: Could not open sample list file $args{'f'}\n";
	
	debug("Loading list of samples to produce pictures for from $args{'f'}\n");
	
	while(<IN>) {
		chomp;
		
		push @inclist, (split /\t/, $_)[0];
	}
	
	close IN;
}

# consolidate include list
if(scalar @inclist) {
	foreach $inc(@inclist) {
		$inc{$inc} = 1;
	}
	
	@inclist = ();
}





# GET SNP INFO
##############

if($args{'s'}) {
	open IN, $args{'s'} or die "ERROR: Could not open SNP info file $args{'s'}\n";
	
	debug("Loading SNP info from $args{'s'}");
	
	$line = 1;
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		# my-style map file
		if(scalar @data == 3) {
			($snp, $chrom, $pos) = @data;
		}
		
		# PLINK-style map file
		elsif(scalar @data == 4) {
			($chrom, $snp, $crap, $pos) = @data;
		}
		
		# or something's wrong!
		else {
			die "ERROR: Problem with SNP file on line $line - incorrect number of columns?\n";
		}
		
		# some checks
		if(($pos !~ /^\d+$/) || ($pos < 0)) {
			warn "WARNING: Illegal position \"$pos\" specified for $snp\n";
			next;
		}
		
		elsif($pos > $length{$chrom}) {
			debug("WARNING: Position of $snp, $pos, is outside specified range (1 - $length{$chrom}); skipping");
		}
		
		if(!$length{$chrom}) {
			debug("WARNING: Chromosome specified for $snp, $chrom, is not recognised; skipping");
			next;
		}
		
		$snp_info{$snp}{'chr'} = $chrom;
		$snp_info{$snp}{'pos'} = $pos;
		
		$snps_by_chrom{$chrom}{$pos} = $snp;
		
		$line++;
	}
	
	close IN;
}

else {
	die "ERROR: No SNP file specified - use the \"-s\" flag\n";
}




# LOAD DATA FILE
################

debug("Reading full sample distribution file");
$line_num = 1;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	if(scalar @data != 3) {
		die "ERROR: Error in data file on line $line_num - incorrect number of columns\n";
	}
	
	else {
		($sample, $snp, $type) = @data;
	}
	
	$all{$snp_info{$snp}{'chr'}}{$snp_info{$snp}{'pos'}} = 1;
	
	if(scalar keys %inc) {
		next unless $inc{$sample};
	}
	
	$data{$sample}{$snp_info{$snp}{'chr'}}{$snp_info{$snp}{'pos'}} = ($type eq "HET" ? 1 : 2);
}




# CALCULATE SOME IMAGE PARAMETERS
#################################

$max_chrom_height = $args{'h'};
$chrom_width = 6;
$gap = 5;

# calculate height and width
$height = $max_chrom_height;
$width = (($args{'x'} ? 25 : 23) * (33 + $gap)) - $gap;



# ITERATE THROUGH EACH SAMPLE FOR WHICH WE ARE GENERATING A PIC
###############################################################

foreach $sample(keys %data) {
	
	# reset x-coord offset
	$x_off = 0;

	# create the image
	$im = new GD::Image($width, $height + 30);
	
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
		$y += $units;
		
		$scaled_y = sprintf("%.0f", ($y / $length{1}) * $height) + $y_off;
		
		$num = $y;
		$num_zeroes = $units =~ tr/0/0/;
		$count = 0;
		
		while($count++ < $num_zeroes) {
			$num =~ s/0$//;
		}
		
		if($num =~ /0$/) {
			$label = ($y / $units);
			$im->string(gdGiantFont, 1, $scaled_y-16, $label, ($num =~ /5$/ ? $darkgrey : $black));
			$im->dashedLine(0, $scaled_y, 50, $scaled_y, ($num =~ /5$/ ? $darkgrey : $black));
		}
	}
	
	
	$x_off = 0;
	
	# ITERATE THROUGH CHROMS
	########################
	
	debug("Plotting chromosomes for sample $sample");
	
	for $chr(1..22,'X','Y') {
	
		# calculate the pixel length of this chromosome
		$length = sprintf("%.0f", ($length{$chr} / $length{1}) * $max_chrom_height);
		
		# skip sex chromosomes unless command line args tell us otherwise
		if($chr !~ /\d/) {
			next unless $args{'x'};
		}
		
		# increment the x-coord offset
		$x_off += 38;
		
		# make two boxes as the outlines
		$im->filledRectangle($x_off + $chrom_width + 1, $y_off + 1, $x_off + $chrom_width + 11, $y_off + $length - 1, $lightred);
		$im->filledRectangle($x_off + $chrom_width + 12, $y_off + 1, $x_off + $chrom_width + 23, $y_off + $length - 1, $lightblue);
		
		# iterate through potential het positions
		foreach $pos(keys %{$all{$chr}}) {
		
			# back-reference to get the SNP ID from the position
			$snp = $snps_by_chrom{$chr}{$pos};
			
			# calculate pixel position for this co-ordinate
			$y = sprintf("%.0f", ($pos / $length{$chr}) * $length) + $y_off;
			
				
			# plot placeholder in track A
			$x1 = $x_off + 1;
			$x2 = $x1 + $chrom_width - 1;
			$im->line($x1, $y, $x2, $y, $grey);
			
			# hets / homs
			if($data{$sample}{$chr}{$pos}) {
				
				# plot het in track B
				if($data{$sample}{$chr}{$pos} == 1) {
					$x1 = $x_off + $chrom_width + 2;
					$x2 = $x1 + 9;
					$im->line($x1, $y, $x2, $y, $red);
				}
				
				# plot hom in track C
				else {
					$x1 = $x_off + $chrom_width + 13;
					$x2 = $x1 + 9;
					$im->line($x1, $y, $x2, $y, $blue);
				}
			}
		}
		
		# outline track A
		$im->rectangle($x_off,$y_off + 1,$x_off + $chrom_width,$y_off + $length-1,$black);
		
		# add ruler
		$units = 1000000;
		$y = 0;
		
		$c = $x_off - 5;
		
		while($y < $length{$chr}) {
			
			$y += $units;
			
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
				$im->line($c + 3, $scaled_y, $c + 4, $scaled_y, $darkgrey);
			}
		}
		
		# write out the image file
		open IM, ">".$args{'o'}.($args{'o'} =~ /\/$/ ? "" : "\.").$sample."\.png" or die "ERROR: Could not write to file $args{'o'}\.$sample\.png\n";
		binmode IM;
		print IM $im->png;
		close IM;
	}
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime();
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
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