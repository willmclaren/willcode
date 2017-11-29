#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;
use CGI qw/:standard/;
use CGI::Pretty;

$usage =<<END;
perl plot.data.on.chrom.pl -s snp.info [-z scale_factor] [-l tracks] data

	-s	snp information file (mandatory)
	-o	specify a stem for output file names
	-z	set scale factor i.e. 1 pixel : z basepairs
	-l	do a log transformation on listed tracks
	-m	add an image map to identify points on the tracks
	-c	draw only these chromosomes (comma separated list)
	-h	set the height of the plot
	-nl	don't join points with lines
	-np	don''t draw points, only lines
	-min	set minimum value for tracks (comma separated list)
	-max	set maximum value for tracks (comma separated list)
	-n	name tracks (comma separated list)
	-nm	don't draw points on the minimum line
END

die $usage unless @ARGV;


# set defaults

$args{'h'} = 110;
$args{'o'} = "~/Documents/Plots/test";


# DEAL WITH ARGUMENTS
#####################

debug("Processing arguments");

# define a list of arguments that have values to shift
%args_with_vals = (
	'z' => 1,
	's' => 1,
	'l' => 1,
	'c' => 1,
	'o' => 1,
	'h' => 1,
	'max' => 1,
	'min' => 1,
	'n' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# process logs
foreach $track(split /\,/, $args{'l'}) {
	$log{$track} = 1;
}

# process chroms
foreach $chrom(split /\,/, $args{'c'}) {
	if($chrom =~ /\./) {
		($chrom, $from, $to) = split /\.|\-/, $chrom;
		
		$range{$chrom}{'from'} = $from;
		$range{$chrom}{'to'} = $to;
	}
	
	$chroms{$chrom} = 1;
}

# process maxes
$track = 1;

foreach $max(split /\,/, $args{'max'}) {
	$maxes{$track} = $max;
	$track++;
}

# process mins
$track = 1;

foreach $min(split /\,/, $args{'min'}) {
	$mins{$track} = $min;
	$track++;
}

# process names
$track = 1;

foreach $name(split /\,/, $args{'n'}) {
	$names{$track} = $name;
	$track++;
}


# GET SNP INFO
##############

if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	debug("Loading SNP info from $args{'s'}");
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		if(scalar @data == 3) {
			($snp, $chrom, $pos) = @data;
		}
		
		elsif(scalar @data == 4) {
			($chrom, $snp, $crap, $pos) = @data;
		}
		
		else {
			die "Error in map file\n";
		}
		
		$snp_info{$snp}{'chr'} = $chrom;
		$snp_info{$snp}{'pos'} = $pos;
		
		($start, $end) = split /\-/, $pos;
		
		$snps_by_chrom{$chrom}{$start} = $snp;
	}
	
	close IN;
}


# LOAD DATA
###########

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	
	$track = 1;
	
	while(@data) {
		$tracks{$track} = 1;
		$point = shift @data;
		
		$point = 1 unless $point =~ /\d/;
		
		# do log transform
		if($log{$track}) {
			$point = log(0.0000000001+$point);
		}
		
		$data{$snp}{$track} = $point;
		
		$seenchroms{$snp_info{$snp}{'chr'}} = 1;
		
		$max{$track} = $point if (($point > $max{$track}) || (!(defined $max{$track})));
		$min{$track} = $point if (($point < $min{$track}) || (!(defined $min{$track})));
		
		$track++;
	}
}

print "Found ".(scalar keys %tracks)." tracks\n";

foreach $track(sort {$a <=> $b} keys %tracks) {
	$min{$track} = (defined $mins{$track} ? $mins{$track} : $min{$track});
	$max{$track} = (defined $maxes{$track} ? $maxes{$track} : $max{$track});
	#$min{$track} = 0 if $max{$track} == $min{$track};
	print "TRACK $track: min = ".$min{$track}.", max = ".$max{$track}."\n";
}


$scale = ($args{'z'} ? $args{'z'} : 40000);


foreach $chrom(sort {$a <=> $b} keys %snps_by_chrom) {
	
	if(scalar keys %chroms) {
		next unless $chroms{$chrom};
	}
	
	next unless $seenchroms{$chrom};

	# get pos list in order
	@sorted_pos = sort {$a <=> $b} keys %{$snps_by_chrom{$chrom}};
	
	
	# find the range of data we are writing to on this chromosome
	@include = ();
	
	foreach $pos(@sorted_pos) {
		if($range{$chrom}) {
			if(($pos >= $range{$chrom}{'from'}) && ($pos <= $range{$chrom}{'to'})) {
				push @include, $pos if $data{$snps_by_chrom{$chrom}{$pos}};
			}
		}
		
		else {
			push @include, $pos if $data{$snps_by_chrom{$chrom}{$pos}};
		}
	}
	
	next unless scalar @include;
	
	$length = $include[-1];
	
	print "Plotting from 0 to $include[-1] on chromosome $chrom\n";
	
	$scaled_length = sprintf("%.0f", $length / $scale);
	
	next unless $length >= 1;
	
	$gd = new GD::Image($scaled_length, $args{'h'});
	
	$white = $gd->colorAllocate(255,255,255);
	$black = $gd->colorAllocate(0,0,0);
	$grey = $gd->colorAllocate(130,130,130);
	$lightgrey = $gd->colorAllocate(220,220,220);
	
	# blues (track 1)
	$col{'1'} = $gd->colorAllocate(0,0,200);
	$lightcol{'1'} = $gd->colorAllocate(200,200,255);
	
	# reds (track 2)
	$col{'2'} = $gd->colorAllocate(200,0,0);
	$lightcol{'2'} = $gd->colorAllocate(255,200,200);
	
	# greens (track 3)
	$col{'3'} = $gd->colorAllocate(0,200,0);
	$lightcol{'3'} = $gd->colorAllocate(200,255,200);
	
	# some other colour (track 4)
	$col{'4'} = $gd->colorAllocate(200,200,0);
	$lightcol{'4'} = $gd->colorAllocate(255,255,200);
	
	# some other colour (track 5)
	$col{'5'} = $gd->colorAllocate(0,200,200);
	$lightcol{'5'} = $gd->colorAllocate(200,255,255);
	
	# some other colour (track 6)
	$col{'6'} = $gd->colorAllocate(200,0,200);
	$lightcol{'6'} = $gd->colorAllocate(255,200,255);
	
	# some other colour (track 7)
	$col{'7'} = $gd->colorAllocate(0,0,0);
	$lightcol{'7'} = $gd->colorAllocate(150,150,150);
		
	# add line
	$gd->line(0,($args{'h'} - 10),$scaled_length,($args{'h'} - 10),$grey);
	
	# add scale
	$units = 1000000;
	$x = 0;
	
	while($x < $include[-1]) {
		
		#print "$x $scaled_x\n";
		$x += $units;
		#next unless $x > $sorted_pos[0];
		
		$scaled_x = sprintf("%.0f", $x / $scale);
		
		$num = $x;
		$num_zeroes = $units =~ tr/0/0/;
		$count = 0;
		
		while($count++ < $num_zeroes) {
			$num =~ s/0$//;
		}
		
		if($num =~ /5$|0$/) {
			$label = ($x / $units)."MB";
			$gd->string(gdTinyFont,$scaled_x+2,2,$label,$black);
			$gd->dashedLine($scaled_x, 0, $scaled_x, $args{'h'}, $grey);
		}
		
		else {
			if($scale <= 30000) {
				$label = ($x / $units)."MB";
				$gd->string(gdTinyFont,$scaled_x+2,2,$label,$grey);
			}
			
			$gd->dashedLine($scaled_x, 0, $scaled_x, $args{'h'}, $lightgrey);
		}
	}
	
	%prev_y = ();
	%prev_x = ();
	$map = '';
	
	foreach $pos(@include) {
		$snp = $snps_by_chrom{$chrom}{$pos};
		
		$scaled_x = sprintf("%.0f", ($pos - $include[0]) / $scale);
	
		foreach $track(keys %tracks) {
			next if (($data{$snp}{$track} == $min{$track}) && $args{'nm'});
			
			$scaled_y = sprintf("%.0f", 20 + (($data{$snp}{$track} - $min{$track})/($max{$track} - $min{$track}) * ($args{'h'} - 30)));
			#$scaled_y = sprintf("%.0f", 20 + ((($max{$track} - $min{$track}) + $data{$snp}{$track})/($max{$track} - $min{$track}) * ($args{'h'} - 30)));
			
			#print "$snp\t$pos\t$scaled_y\t$data{$snp}{$track}\tend\n";
		
			if($prev_y{$track} && $prev_x{$track} && !$args{'nl'}) {
				$gd->line($scaled_x, $scaled_y, $prev_x{$track}, $prev_y{$track}, ($args{'np'} ? $col{$track} : $lightcol{$track}));
			}
			
			unless($args{'np'}) {
				$gd->line($scaled_x, $scaled_y-4, $scaled_x, $scaled_y+4, $col{$track});
				$gd->line($scaled_x-2, $scaled_y, $scaled_x+2, $scaled_y, $col{$track});
			}
			
			
			if($args{'m'}) {
				$map .= "\n".
					"<area shape=\"rect\" ".
					"coords=\"".
						($scaled_x-1).",".
						($scaled_y-1).",".
						($scaled_x+2).",".
						($scaled_y+2).
					"\" title=\"".($names{$track} ? $names{$track} : $track)." \| $snp \| $pos \| $data{$snp}{$track}\" ".
					"href=\"http://www.ensembl.org/Homo_sapiens/snpview?snp=$snp\"></area>";
			}
						
			
			$prev_y{$track} = $scaled_y;
			$prev_x{$track} = $scaled_x;
		}
	}
	
	# write out the GD object
	$img_out = ($args{'o'} ? $args{'o'}."_" : "")."chr$chrom.png";
	$img_link = (split /\//, $img_out)[-1];
	
	open IM, ">$img_out";
	binmode IM;
	print IM $gd->png;
	close IM;
	
	push @rows,
		Tr(
			td(
				$chrom,
			),
			td(
				#(
				#	{-href => $img_link},
					img({-border => 0, -src => $img_link, -usemap => "#$chrom"}),
				#),
			),
		);
		
	$maps .= "<map id=\"$chrom\" name=\"$chrom\">".$map."\n</map>",
}

close OUT;

# make the legend
%legcolours = (
	1 => '#0000C8',
	2 => '#C80000',
	3 => '#00C800',
	4 => '#C8C800',
	5 => '#00C8C8',
	6 => '#C800C8',
);

foreach $track(sort {$a <=> $b} keys %tracks) {
	push @legrows, (
		Tr(
			td(
				{-bgcolor => $legcolours{$track}},
				"&nbsp;",
			),
			td(
				(defined $names{$track} ? $names{$track} : "TRACK $track"),
			),
		)
	);
}

open OUT, ">".($args{'o'} ? $args{'o'} : "plot").".html";

print OUT
	start_html($args{'o'}),
	$maps,
	table(
		{-border => 0, -cellspacing => 20},
		Tr(
			\@rows,
		),
		
		Tr(
			"&nbsp;",
		),
		
		# legend
		Tr(
			\@legrows,
		),
	),
	end_html;

close OUT;

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
