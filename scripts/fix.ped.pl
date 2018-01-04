#!/usr/bin/perl

use Tie::File;

foreach $file(@ARGV) {
	tie @all, 'Tie::File', $file;
	
	# identify samples with duplicate lines
	$line_num = 0;
	
	foreach(@all) {
		$sample = substr($_, 0, 30);
		$sample =~ s/\t.+//g;
		
		push @{$locs{sample}}, $line_num;
		$line_num++;
	}
	
	# now go through each of the ones with duplicates
	foreach $sample(keys %locs) {
		next unless (scalar @{$locs{$sample}}) > 1;
		
		@lines = ();
		
		# add split line arrays to an array
		foreach $i(@{$locs{$sample}}) {
			@split = split /\t/, $all[$i];
		
			push @lines, \@split;
		}
		
		# iterate through line horizontally
		for($i=0;$i<(scalar @{$lines[0]});$i++) {
			next unless $lines[0]->[$i] =~ / /;
			
			# if we have missing data
			if($lines[0]->[$i] eq '0 0') {
				foreach $line(@lines) {
				
					# substitute with real data
					if($line->[$i] ne '0 0') {
						$lines[0]->[$i] = $line->[$i];
						last;
					}
				}
			}
		}
		
		$first = 1;
		
		foreach $i(@{$locs{$sample}}) {
			if($first) {
				$all[$i] = (join "\t", @{$lines[0]});
				$first = 0;
			}
			
			else {
				$all[$i] = '0';
			}
		}
	}
	
	# clean up lines that got deleted
	
	# close the file
	untie @all;
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
