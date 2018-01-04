#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl/';
use Spreadsheet::ParseExcel;

$file = shift @ARGV;
$stem = (split /\//, $file)[-1];
$stem =~ s/\.xls//;

$excel = new Spreadsheet::ParseExcel;
$spread = $excel->Parse($file);

system "mkdir $stem";

foreach $sheet(@{$spread->{Worksheet}}) {
	open OUT, ">$stem/".$sheet->{Name};
	
	for($row = $sheet->{MinRow}; defined $sheet->{MaxRow} && $row <= $sheet->{MaxRow}; $row++) {
	#foreach $row(@{$sheet->{Cells}}) {
		$first = 1;
	
		for($col = $sheet->{MinCol}; defined $sheet->{Cells}[$row][$col] && defined $sheet->{MaxCol} && $col <= $sheet->{MaxCol}; $col++) {
		#foreach $col(@{$sheet->{Cells}[$row]}) {
			$cell = $sheet->{Cells}[$row][$col];
			print OUT ($first ? "" : "\t").($cell->Value());
			$first = 0;
		}
		
		print OUT "\n";
	}
	
	close OUT;
}

