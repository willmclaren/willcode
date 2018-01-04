#!/usr/bin/perl

# define a list of arguments that have values to shift
%args_with_vals = (
	'o' => 1,
);

# defaults
$args{'o'} = "combined";

# get the arguments into the hash
while($ARGV[0] =~ /^\-.+/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

while(@ARGV) {
	$map = shift @ARGV or die "Map file not supplied for $ped\n";
	$ped = shift @ARGV;
	
	push @peds, $ped;
	$handles{$ped} = newopen($ped);
	
	debug("Loading map file $map");

	open MAP, $map or die "Could not read map file $map for ped file $ped\n";
	
	while(<MAP>) {
		next if /\s+chr\s+/i;
		#print;
		
		chomp;
		
		# lose any leading whitespace
		$_ =~ s/^\s+//g;
		
		@data = split /\s+/, $_;
		
		if(scalar @data == 3) {
			$marker = shift @data;
			$chrom = shift @data;
			$pos = shift @data;
		}
		
		else {
			$chrom = shift @data;
			$marker = shift @data;
			$crap = shift @data;
			$pos = shift @data;
		}
		
		$map{$ped}{$chrom}{$pos} = $marker;
	}
	
	close MAP;
}

$line_num = 1;

debug("Writing ped data to $args{'o'}\.ped");

open OUT, ">".$args{'o'}.".ped";

LOOP: while(1) {
	$first = 1;
	%d = ();

	foreach $ped(@peds) {
		$handle = $handles{$ped};
		$line = <$handle> or die "Could not read from $ped\n";
		#print $line;
		chomp $line;
		@data = split /\s+/, $line;
		
		if($first) {
			for(1..5) {
				print OUT shift @data;
				print OUT "\t";
			}
			
			print OUT shift @data;
		}
		
		else {
			for(1..6) {
				shift @data;
			}
		}
		
		$marker_num = 1;
		
		foreach $chrom(sort {$a <=> $b} keys %{$map{$ped}}) {
			foreach $pos(sort {$a <=> $b} keys %{$map{$ped}{$chrom}}) {
				$a = shift @data;
					#or die "Too few markers ($marker_num - should be ".(scalar keys %{$map{$ped}{$chrom}}).") on line $line_num in file $ped";
				$b = shift @data;
					#or die "Too few markers ($marker_num - should be ".(scalar keys %{$map{$ped}{$chrom}}).") on line $line_num in file $ped";
				
				$d{$chrom}{$pos}{$ped} = $a."_".$b;
				
				#print "DEBUG: $ped\t$pos\t$marker_num\t$a $b\n";
				
				$marker_num++;
			}
		}
		
		$first = 0;
	}
	
	foreach $chrom(sort {$a <=> $b} keys %d) {
		foreach $pos(sort {$a <=> $b} keys %{$d{$chrom}}) {
			if(scalar keys %{$d{$chrom}{$pos}} > 1) {
				$match = 1;
				$prev = "0\_0";
				
				foreach $ped(keys %{$d{$chrom}{$pos}}) {
					next if $d{$chrom}{$pos}{$ped} =~ /0/;
				
					if($prev ne "0\_0") {
						$match = 0 unless $d{$chrom}{$pos}{$ped} eq $prev;
					}
					$prev = $d{$chrom}{$pos}{$ped};
				}
				
				if($match) {
					print OUT "\t".(join " ", (split /\_/, $prev));
				}
				
				else {
					print OUT "\t0 0";
					#debug("Mismatch at $pos");
				}
			}
			
			else {
				foreach $ped(keys %{$d{$chrom}{$pos}}) {
					$geno = (join " ", (split /\_/, $d{$chrom}{$pos}{$ped}));
# 					if($geno !~ /\d/) {
# 						debug("Why is this happening? $ped $pos g:\_$geno\_");
# 						$geno = $ped." ".$pos;
# 					}
					
					print OUT "\t".$geno;
				}
			}
		}
	}
	
	print OUT "\n";
	$line_num++;
	
	#die;
	
	last LOOP if eof($handle);
}
close OUT;

debug("Writing map file to $args{'o'}\.map");
#open OUT, ">combined.map";
open OUT, ">".$args{'o'}.".map";

foreach $chrom(sort {$a <=> $b} keys %d) {
	foreach $pos(sort {$a <=> $b} keys %{$d{$chrom}}) {
		foreach $ped(keys %map) {
			$marker = $map{$ped}{$chrom}{$pos} if $map{$ped}{$chrom}{$pos};
		}
		
		print OUT "$chrom\t$marker\t0\t$pos\n";
	}
}


sub newopen {
	my $path = shift;
	local *FH;
	open(FH, $path) or return undef;
	return *FH;
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