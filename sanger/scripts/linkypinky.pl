#!/usr/bin/perl

$args{'s'} = "/nfs/team71/psg/wm2/Farm/work/Affy/data/snp.info";

%args_with_vals = (
	't' => 1,
	's' => 1,
	'c' => 1,
	'o' => 1,
	'p' => 1,
	'r' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}



$snpfile = $args{'s'};
open IN, $snpfile or die "Could not read from SNP file $snpfile\n";

debug("Reading SNP info from $snpfile");

while(<IN>) {
	chomp;
	
	@split = split /\s+/, $_;
	
	if(scalar @split == 3) {
		($snp, $chr, $pos) = @split;
	}
	
	else {
		($chr, $snp, $crap, $pos) = @split;
	}
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
	$snps{$chr}{$pos} = $snp;
}

close IN;

debug("Read data for ".(scalar keys %pos)." SNPs");


while(<>) {
	chomp;
	
	($sample, $snpa, $snpb, $type) = split /\s+/, $_;
	
	next unless defined $pos{$snpa} && defined $pos{$snpb};
	next unless $type eq "WRONG";
	
	($posa, $posb) = ($pos{$snpa}, $pos{$snpb});
	
	if($posa > $posb) {
		$data{$sample}{$snpa}{$snpb} = $type;
	}
	
	else {
		$data{$sample}{$snpb}{$snpa} = $type;
	}
}

foreach $sample(keys %data) {
	foreach $snpa(keys %{$data{$sample}}) {
		if(scalar keys %{$data{$sample}{$snpa}} == 1) {
			print "$sample\t$snpa\t".(join "", keys %{$data{$sample}{$snpa}})."\tWRONG\n";
		}
		
		else {
			%temp = ();
			
			foreach $snpb(keys %{$data{$sample}{$snpa}}) {
				$temp{$snpb} = $pos{$snpa} - $pos{$snpb};
			}
			
			$closest = (sort {$temp{$snpb} <=> $temp{$snpa}} keys %temp)[0];
			
			print "$sample\t$snpa\t$closest\tWRONG\n";
		}
	}
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
# 		($time[5] + 1900)."-".
# 		$time[4]."-".
# 		$time[3]." ".
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime;
	my $pid = $$;
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
}
