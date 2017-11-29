#!/usr/bin/perl

while(<>) {
	chomp;
	
	@bits = split /\./, $_;
	
	shift @bits;
	pop @bits;
	
	$new = join '.', @bits;
	
	system "cat OB/BRLMM/OB\.$new\.keep OBC/BRLMM/OBC\.$new\.move > OB/BRLMM/OB\.$new\.new";
	print "\n";
	system "cat OBC/BRLMM/OBC\.$new\.keep OB/BRLMM/OB\.$new\.move > OBC/BRLMM/OBC\.$new\.new";
	print "\n";
}