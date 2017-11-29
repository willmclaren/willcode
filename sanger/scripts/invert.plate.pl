#!/usr/bin/perl

while(<>) {
	chomp;
	
	($sample, $well, $cohort) = split /\t/, $_;
	
	$row = substr($well, 5, 1);
	$col = substr($well, 6);
	
	$original{$row}{$col} = $sample;
	$cohort{$sample} = $cohort;
}

@rows = sort keys %original;
@cols = 1..12;

foreach $from_row_num(0..$#rows) {
	$to_row_num = -1 - $from_row_num;

	foreach $from_col_num(0..$#cols) {
		$to_col_num = -1 - $from_col_num;
		
		$switched{$rows[$from_row_num]}{$cols[$from_col_num]} = $original{$rows[$to_row_num]}{$cols[$to_col_num]};
	}
}

foreach $row(@rows) {
	foreach $col(@cols) {
		print "$original{$row}{$col}\t$cohort{$original{$row}{$col}}\t$switched{$row}{$col}\t$cohort{$switched{$row}{$col}}\t15575$row$col\n";
	}
}