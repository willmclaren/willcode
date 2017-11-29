#!/usr/bin/perl

$args{'t'} = 0.01;
$args{'o'} = "RHHlink";

%args_with_vals = (
	't' => 1,
	's' => 1,
	'c' => 1,
	'o' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

open IN, $args{'c'} or die ($args{'c'} ? "Could not open counts file $args{'c'}\n" : "Counts file not specified (-c)\n");
print "Reading counts file $args{'c'}\n";

while(<IN>) {
	next if /NN/;
	next if /00/;
	next if /Reading/;

	chomp;
	
	($snpa, $snpb, $genoa, $genob, $count) = split /\t/, $_;
	
	next unless (($genoa =~ /a|c|g|t|1|2|3|4/i) && ($genob =~ /a|c|g|t|1|2|3|4/i));
	
	$counts{$snpa." ".$snpb}{$genoa." ".$genob} = $count;
	$totals{$snpa." ".$snpb} += $count;
	
	$present{$snpa} = 1;
	$present{$snpb} = 1;
}

close IN;

print "Calculating rare status for LD pairs\n";

foreach $pair(keys %counts) {
	($snpa, $snpb) = split / /, $pair;

	foreach $geno(keys %{$counts{$pair}}) {
		$rare{$snpa}{$snpb}{$geno} = 1 if ($counts{$pair}{$geno} / $totals{$pair}) <= $args{'t'};
		
		#print "Rare $pair $geno\n" if ($counts{$pair}{$geno} / $totals{$pair}) <= $thresh;
	}
}


open IN, $args{'s'} or die ($args{'s'} ? "Could not open SNP file $args{'s'}\n" : "SNP file not specified (-s)\n");
print "Reading SNP file $args{'s'}\n";

while(<IN>) {
	chomp;
	
	if($args{'p'}) {
		($chr, $snp, $crap, $pos) = split /\t/, $_;
	}
	else {
		($snp, $chr, $pos) = split /\t/, $_;
	}
	
	push @order, $snp;
}

close IN;



# $file = shift @ARGV;
# open IN, $file;
open FULL, ">".$args{'o'}."_full.dist";
open OUT, ">".$args{'o'}."_sample.dist";

print "Reading and processing data\n";

while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	$sample = shift @data;
	
	if($args{'p'}) {
		for(1..5) {
			shift @data;
		}
	}
		
	$num = 0;
	
	while(@data) {
		
		if($args{'p'}) {
			$geno = shift @data;
			$geno .= shift @data;
		}
		
		else {
			$geno = shift @data;
		}
		$snp = $order[$num];
		$num++;
		
		next unless $present{$snp};
		
		$geno{$snp} = $geno;
	}
	
	$null = 0;
	$right = 0;
	$wrong = 0;
	
	foreach $a(keys %rare) {
		foreach $b(keys %{$rare{$a}}) {
			print FULL "$sample\t$a\t$b\t";
		
			if(($geno{$a} !~ /a|c|g|t|1|2|3|4/i) || ($geno{$b} !~ /a|c|g|t|1|2|3|4/i)) {
				$null++;
				
				print FULL "NULL";
			}
			
			elsif($rare{$a}{$b}{$geno{$a}." ".$geno{$b}}) {
				$wrong++;
				
				print FULL "WRONG";
			}
			
			if(!$counts{$a." ".$b}{$geno{$a}." ".$geno{$b}}) {
				$missing++;
				
				print FULL "MISSING";
			}
			
			else {
				$right++;
				
				print FULL "RIGHT";
			}
			
			print FULL "\n";
		}
	}
	
	print OUT "$sample\t$right\t$wrong\t$null\t".(($wrong || $right) ? (100*$wrong/($right+$wrong)) : 0)."\n";
}

print "Done\n";