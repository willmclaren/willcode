#!/usr/bin/perl

$reverse = 0;
$delim = "\t";

while($ARGV[0] =~ /\-/) {
	if($ARGV[0] =~ /r/i) {
		$reverse = 1;
		shift @ARGV;
	}
	
	elsif($ARGV[0] =~ /a/i) {
		$alphabetical = 1;
		shift @ARGV;
	}
	
	elsif($ARGV[0] =~ /h/i) {
		$header = 1;
		shift @ARGV;
	}
	
	elsif($ARGV[0] =~ /d/i) {
		shift @ARGV;
		$delim = shift @ARGV;
	}
}

$sortcol = 1;

$sortcol = shift @ARGV if $ARGV[0] =~ /^\d/;

if($sortcol =~ /\,/) {
	@sortcols = split /\,/, $sortcol;
	
	for $i(0..$#sortcols) {
		$sortcols[$i]--;
	}
}

$sortcol--;


$row = 0;
$first = 1;

while(<>) {
	if($first && $header) {
		print;
		$first = 0;
	}
	
	else {

		chomp;
		
		@line = split /$delim/, $_;
		
		for $col(0..$#line) {
			$data{$row}{$col} = $line[$col];
		}
		
		$row++;
	}
}

if(scalar @sortcols == 2) {
	@list = sort {
		$data{$a}{$sortcols[0]} <=> $data{$b}{$sortcols[0]} ||
		$data{$a}{$sortcols[1]} <=> $data{$b}{$sortcols[1]}
	} keys %data;
}

elsif(scalar @sortcols == 3) {
	@list = sort {
		$data{$a}{$sortcols[0]} <=> $data{$b}{$sortcols[0]} ||
		$data{$a}{$sortcols[1]} <=> $data{$b}{$sortcols[1]} ||
		$data{$a}{$sortcols[2]} <=> $data{$b}{$sortcols[2]}
	} keys %data;
}

elsif($alphabetical) {
	@list = sort {$data{$a}{$sortcol} cmp $data{$b}{$sortcol}} keys %data;
}

else {
	@list = sort {$data{$a}{$sortcol} <=> $data{$b}{$sortcol}} keys %data;
}

if($reverse) {
	@list = reverse @list;
}
		

foreach $row(@list) {
	#print "$row\n";
	
	$first = 1;
	
	foreach $col(sort {$a <=> $b} keys %{$data{$row}}) {
		print ($first ? "" : $delim);
		print $data{$row}{$col};
		$first = 0;
	}
	
	print "\n";
}