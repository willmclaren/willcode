#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;
use CGI qw/:standard/;
use CGI::Pretty;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chrom, $pos) = split /\t/, $_;
	
	$snps{$chrom}{$pos} = $snp;
	$chrom{$snp} = $chrom;
	$pos{$snp} = $pos;
}

close IN;

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($chrom, $length) = split /\s+/, $_;
	
	$length{$chrom} = $length;
}

close IN;

$longest = (sort {$a <=> $b} values %length)[-1];
$max_chrom_height = 600;
$chrom_width = 20;


while(<>) {
	next unless /HET/;
	
	chomp;
	
	($sample, $snp, $type) = split /\t/, $_;
	
	$hets{$snp} = 1;
}



for $chr(1..22) {
	$length = sprintf("%.0f", ($length{$chr} / $longest) * $max_chrom_height);
	
	#print "Plotting chromosome $chr, length $length\n";
	
	# start a GD object for this chromosome
	$im = new GD::Image($chrom_width+1,$length);
	
	# allocate some colors
	$white = $im->colorAllocate(255,255,255);
	$black = $im->colorAllocate(0,0,0);
	$grey = $im->colorAllocate(200,200,200);
	$red = $im->colorAllocate(230, 0, 0);
	
	# draw the side lines of the chrom
	$im->line(0,($chrom_width/2),0,($length-($chrom_width/2)),$black);
	$im->line($chrom_width,($chrom_width/2),$chrom_width,($length-($chrom_width/2)),$black);
	
	# draw arcs at the top and bottom
	$im->arc(($chrom_width/2),($chrom_width/2),$chrom_width,$chrom_width,180,0,$black);
	$im->arc(($chrom_width/2),$length-($chrom_width/2),$chrom_width,$chrom_width,0,180,$black);
	
	# fill the chrom
	$im->fill(($chrom_width/2), ($length/2), $grey);
	
	foreach $snp(keys %hets) {
		next unless $chrom{$snp} == $chr;
		$pos = $pos{$snp};
		
		$y = sprintf("%.0f", ($pos / $length{$chr}) * $length);
				
		$x1 = $chrom_width - 1;
		
		$im->line(1, $y, $x1, $y, $red);
	}
	
	# write out the image file
	open IM, ">test.chr$chr.png";
	binmode IM;
	print IM $im->png;
	close IM;
	
	push @row,
		table(
			{-border => 0, -cellpadding => 0, -cellspacing => 0, -height => "100%"},
			Tr(
				td(
					{-align => "center"},
					$chr,
				),
			),
			Tr(
				{-valign => "top"},
				td(
					{-height => "100%"},
					img({-src => "test.chr$chr.png"}),
				),
			),
		);
}


print
	start_html,
	table(
		{-border => 0, -cellpadding => 10, -cellspacing => 0},
		Tr(
			{-valign => "top"},
			td(
				{-height => "100%"},
				\@row,
			),
		),
	),
	end_html;