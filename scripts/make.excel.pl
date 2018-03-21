#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use Spreadsheet::WriteExcel;
use Spreadsheet::WriteExcel::Big;

if($ARGV[0] =~ /\-b/) {
	shift @ARGV;
	
	$big = 1;
}

$filename = shift @ARGV;

my $workbook;

if($big) {
	$workbook = Spreadsheet::WriteExcel::Big->new("$filename".($filename =~ /xls$/i ? "" : ".xls"));
}

else {
	$workbook = Spreadsheet::WriteExcel->new("$filename".($filename =~ /xls$/i ? "" : ".xls"));
}

print "Writing to file $filename\n";

foreach $file(@ARGV) {
	open IN, $file;
	
	$name = substr((split /\//, $file)[-1], 0, 30);
	
	$sheets{$file} = $workbook->add_worksheet($name);
	
	$row = 0;
	
	while(<IN>) {
		chomp;
		
		@data = split /\t/, $_;
		
		for $col(0..$#data) {
			$sheets{$file}->write($row, $col, $data[$col]);
		}
		
		$row++;
	}
	
	close IN;
}

$workbook->close();