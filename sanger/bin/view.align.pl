#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';
use CGI qw/:standard/;
use CGI::Pretty;

$seqnum = 1;

%colours = (
	A => 'red',
	C => 'green',
	G => 'yellow',
	T => 'blue'
);

while(<>) {
	if(/^\>/) {
		$id = $_;
		$id =~ s/^\>//g;
		
		$seq = <>;
		
		chomp $seq;
		chomp $id;
		
		$id{$seqnum} = $id;
		$seq{$seqnum} = $seq;
		
		$seqnum++;
	}
}





#open OUT, ">~/Documents/align.html";

print #OUT
	start_html,
	"<table cellpadding=0 cellspacing=0 style=\"font-size:6px;\">";
	
foreach $num(sort {$seq{$a} cmp $seq{$b}} keys %id) {
	print "<tr>";
	
	foreach $base(split //, $seq{$num}) {
		print "<td bgcolor=\"$colours{$base}\">&nbsp;</td>";
	}
	
	print "</tr>";
}
	
print
	"</table>",
	end_html;