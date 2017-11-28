#!/usr/bin/perl

my $a = shift;
my $b = shift;

my $tmp_a = "\.".$$."_a";
my $tmp_b = "\.".$$."_b";

while(<>) {
	chomp;
	my $line = $_;
	my @data = split /\t/, $_;
	
	open OUTA, ">$tmp_a";
	open OUTB, ">$tmp_b";
	
	print OUTA $data[$a], "\n";
	print OUTB $data[$b], "\n";
	
	close OUTA;
	close OUTB;
	
	open IN, "diff $tmp_a $tmp_b |";
	while(<IN>) {
		print;
	}
	close IN;
}

system "rm $tmp_a $tmp_b";