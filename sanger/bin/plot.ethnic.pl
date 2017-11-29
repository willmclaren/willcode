#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use GD;
use CGI qw/:standard/;
use CGI::Pretty;

$usage =<<END;
perl ethnic.freqs.pl
	-r	Reference panel ID
	-e	Other population ID
	-o	Output file stem
	-l	List of markers in panel
	-f	Frequency data file
	-d	Distance to reduce SNP panel using
	-s	SNP information file for reducing distance
END

die $usage unless @ARGV;

# define some stuff
@pop_order = qw/CEU CHB JPT YRI CHB+JPT/;

# DEAL WITH ARGUMENTS
#####################

debug("Processing arguments");

# define a list of arguments that have values to shift
%args_with_vals = (
	'f' => 1,
	'l' => 1,
	'r' => 1,
	'e' => 1,
	'o' => 1,
	'd' => 1,
	's' => 1,
);

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

# process the arguments
$args{'r'} = "\U$args{'r'}";
$args{'e'} = "\U$args{'e'}";

die "Invalid reference population identifier \"$args{'r'}\" given\n" unless $args{'r'} =~ /CEU|CHB|JPT|YRI/;
die "Invalid ethnic group population identifier \"$args{'e'}\" given\n" unless $args{'e'} =~ /CEU|CHB|JPT|YRI/;


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


# GET SNP LIST
##############

open IN, $args{'l'} or die ($args{'l'} ? "Could not open list file $args{'l'}\n" : "SNP list file not specified - use -l list_file\n");

debug("Loading SNP list from $args{'l'}");

while(<IN>) {
	chomp;
	
	$list{(split /\t/, $_)[0]} = 1;
}

close IN;

debug("List contains ".(scalar keys %list)." SNPs");

# $genofile = shift @ARGV;

# ELIMINATE SNPS
################

if($args{'d'} && $args{'s'}) {
	debug("Scanning genotype file to get final SNP list");

	# we need to scan the genotypes file first
	open GENO, $genofile;
	
	while(<GENO>) {
		chomp;
		
		($snp, $samp, $geno, $crap) = split /\s+/, $_;
		
		$in_file{$snp} = 1;
	}
	
	close GENO;

	foreach $snp(sort {$snp_info{$a}{'chr'} <=> $snp_info{$b}{'chr'} || $snp_info{$a}{'pos'} <=> $snp_info{$b}{'pos'}} keys %list) {
		delete $list{$snp} unless $in_file{$snp};
	
		if(($snp_info{$snp}{'chr'} == $prev_chrom) && (($snp_info{$snp}{'pos'} - $prev_pos) < $args{'d'})) {
			delete $list{$snp};
		}
		$prev_pos = $snp_info{$snp}{'pos'};
		$prev_chrom = $snp_info{$snp}{'chr'}
	}
	
	debug("List pruned to ".(scalar keys %list)." SNPs");
}

# GET FREQUENCY DATA
####################

open IN, $args{'f'} or die ($args{'f'} ? "Could not open frequency file $args{'f'}\n" : "Frequency file not specified - use -f freq_file\n");

debug("Loading frequency data from $args{'f'}");

SNP: while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$snp = shift @data;
	next unless $list{$snp};
	
	foreach $pop(@pop_order) {
		$allele_a = shift @data;
		$freq_a = shift @data;
		$allele_b = shift @data;
		$freq_b = shift @data;
		
		if((join "", (sort ($allele_a, $allele_b))) =~ /AT|CG/i) {
			delete $list{$snp};
			$excluded{$snp} = 1;
			next SNP;
		}
		
		#print "$snp\t$pop\t$args{'r'}\t$args{'e'}\t$allele_a\t$freq_a\t$allele_b\t$freq_b\n";
		
		if($pop eq $args{'r'}) {
# 			unless($allele_a =~ /acgt/i) {
# 				delete $list{$snp};
# 				next;
# 			}
		
			$freqs{$snp}{'r'}{$allele_a} = $freq_a;
			$freqs{$snp}{'r'}{$allele_b} = $freq_b;
		}
		
		elsif($pop eq $args{'e'}) {
# 			unless($allele_a =~ /acgt/i) {
# 				delete $list{$snp};
# 				next;
# 			}
		
			$freqs{$snp}{'e'}{$allele_a} = $freq_a;
			$freqs{$snp}{'e'}{$allele_b} = $freq_b;
		}
	}
}

close IN;


debug("Loaded data for ".(scalar keys %freqs)." SNPs");
debug((scalar keys %excluded)." SNPs rejected for strand ambiguity");



# GO THROUGH GENOTYPING DATA
############################

debug("Parsing genotype data");

# open GENO, $genofile;

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $num) = split /\t/, $_;
	
    # check the SNP is in the list
	next unless $list{$snp};
	
    # skip if missing genotype
	next if $geno =~ /n/i;

	# check that the alleles in this genotype appear in the freqs hash
	$found = 0;
	
    foreach $allele(split //, $geno) {
		$found = 1 if $freqs{$snp}{'e'}{$allele};
	}
	
	if(!$found) {
		$cheese = 1;
	}
	
	
	if(isHet($geno)) {
		$dist{$snp} = 2;
		#print "$sample\t$snp\t$geno\t$args{'r'}\t".$freqs{$snp}{'r'}{substr($geno,0,1)}."\t$args{'e'}\t".$freqs{$snp}{'e'}{substr($geno,0,1)}."\n";
		
	}
	
	else {
		#print "$sample\t$snp\t$geno\t$args{'r'}\t".$freqs{$snp}{'r'}{substr($geno,0,1)}."\t$args{'e'}\t".$freqs{$snp}{'e'}{substr($geno,0,1)}."\n";
		
		# flip reverse it if necessary
		unless($freqs{$snp}{'e'}{substr($geno,0,1)}) {
			$geno =~ tr/ACGT/TGCA/;
		}
		
		if($freqs{$snp}{'r'}{substr($geno,0,1)} == 0) {
			$dist{$snp} = 3;
		}
		
		else {
			$dist{$snp} = 1;
		}
	}
}


$scale = 50000;

open OUT, ">".($args{'o'} ? $args{'o'}."_" : "")."eth.list";

foreach $chrom(sort {$a <=> $b} keys %snps_by_chrom) {
	#debug("Writing image for chromosome $chrom");

	# get pos list in order
	@sorted_pos = sort {$a <=> $b} keys %{$snps_by_chrom{$chrom}};
	
	$length = $sorted_pos[-1] - $sorted_pos[0];
	
	$scaled_length = sprintf("%.0f", $length / $scale);
	
	$gd = new GD::Image($scaled_length, 60);
	
	$white = $gd->colorAllocate(255,255,255);
	$black = $gd->colorAllocate(0,0,0);
	$grey = $gd->colorAllocate(130,130,130);
	$lightgrey = $gd->colorAllocate(220,220,220);
	
	$blue = $gd->colorAllocate(0,0,200);
	$red = $gd->colorAllocate(200,0,0);
	$green = $gd->colorAllocate(0,200,0);
	
	$lightblue = $gd->colorAllocate(0,0,255);
	$lightred = $gd->colorAllocate(255,0,0);
	$lightgreen = $gd->colorAllocate(0,255,0);
		
	# add line
	$gd->line(0,50,$scaled_length,50,$black);
	
	# add scale
	$units = 1000000;
	$x = 0;
	
	while($x < $sorted_pos[-1]) {
		
		#print "$x $scaled_x\n";
		$x += $units;
		#next unless $units > $sorted_pos[0];
		
		$scaled_x = sprintf("%.0f", $x / $scale);
		
		$num = $x;
		$num_zeroes = $units =~ tr/0/0/;
		$count = 0;
		
		while($count++ < $num_zeroes) {
			$num =~ s/0$//;
		}
		
		if($num =~ /5$|0$/) {
			$label = ($x / $units)."MB";
			$gd->string(gdTinyFont,$scaled_x+2,2,$label,$grey);
			$gd->dashedLine($scaled_x, 0, $scaled_x, 60, $grey);
		}
		
		else {
			$gd->dashedLine($scaled_x, 0, $scaled_x, 60, $lightgrey);
		}
	}
	
	$prev_all = '';
	
	foreach $pos(@sorted_pos) {
	
		$scaled_pos = sprintf("%.0f", $pos / $scale);
	
		$snp = $snps_by_chrom{$chrom}{$pos};
		next unless $dist{$snp};
		
		if($dist{$snp} == 1) {
			$gd->filledRectangle($scaled_pos,45,$scaled_pos,55, $green);
			
			if($prev_all == $dist{$snp}) {
				$gd->filledRectangle($prev_pos,45,$scaled_pos,55, $green);
				
				$gd->line($prev_pos - 2, 43, $prev_pos, 45, $black);
				$gd->line($prev_pos + 2, 43, $prev_pos, 45, $black);
				
				$gd->line($scaled_pos - 2, 43, $scaled_pos, 45, $black);
				$gd->line($scaled_pos + 2, 43, $scaled_pos, 45, $black);
				
				$gd->filledRectangle($scaled_pos,45,$scaled_pos,55, $black);
				$gd->filledRectangle($prev_pos,45,$prev_pos,55, $black);
			}
		}
		
		elsif($dist{$snp} == 2) {
			$gd->filledRectangle($scaled_pos,30,$scaled_pos,40, $red);
			
			if($prev_all == $dist{$snp}) {
				$gd->filledRectangle($prev_pos,30,$scaled_pos,40, $red);
				
				$gd->line($prev_pos - 2, 28, $prev_pos, 30, $black);
				$gd->line($prev_pos + 2, 28, $prev_pos, 30, $black);
				
				$gd->line($scaled_pos - 2, 28, $scaled_pos, 30, $black);
				$gd->line($scaled_pos + 2, 28, $scaled_pos, 30, $black);
				
				$gd->filledRectangle($scaled_pos,30,$scaled_pos,40, $black);
				$gd->filledRectangle($prev_pos,30,$prev_pos,40, $black);
			}
		}
		
		elsif($dist{$snp} == 3) {
			$gd->filledRectangle($scaled_pos,15,$scaled_pos,25, $blue);
			
			if($prev_all == $dist{$snp}) {
				$gd->filledRectangle($prev_pos,15,$scaled_pos,25, $blue);
				
				$gd->line($prev_pos - 2, 13, $prev_pos, 15, $black);
				$gd->line($prev_pos + 2, 13, $prev_pos, 15, $black);
				
				$gd->line($scaled_pos - 2, 13, $scaled_pos, 15, $black);
				$gd->line($scaled_pos + 2, 13, $scaled_pos, 15, $black);
				
				$gd->filledRectangle($scaled_pos,15,$scaled_pos,25, $black);
				$gd->filledRectangle($prev_pos,15,$prev_pos,25, $black);
			}
		}
		
		print OUT "$snp\t$chrom\t$pos\t$dist{$snp}\n";
		
		$prev_all = $dist{$snp};
		$prev_pos = $scaled_pos;
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
				a(
					{-href => $img_link},
					img({-border => 0, -src => $img_link}),
				),
			),
		);
}

close OUT;

open OUT, ">".($args{'o'} ? $args{'o'} : "plot").".html";

print OUT
	start_html($args{'o'}),
	table(
		{-border => 0, -cellspacing => 20},
		Tr(
			\@rows,
		),
	),
	end_html;

close OUT;

# SUBROUTINE TO IDENTIFY HETS
#############################

sub isHet {
	$geno = shift;
	
	$result = 0;
	
	$result = 1 if substr($geno,0,1) ne substr($geno,1,1);
	
	return $result;
}


# SUBROUTINE TO IDENTIFY HOMS
#############################

sub isHom {
	$geno = shift;
	
	$result = 0;
	
	return $result if $geno =~ /n/i;
	
	$result = 1 if substr($geno,0,1) eq substr($geno,1,1);
	
	return $result;
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