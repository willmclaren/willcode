#!/usr/bin/perl

$tabsize = 8;

for(1..10) {
	$w = 75;
	$prev = 0;
	
	$in = <> or last;
	
	if($in =~ /\t/) {
		
		while(($in =~ m/\t/g) && ($w > 50)) {
			$pos = pos $in;
			$rel = $pos - $prev;
			
			$sub = substr($in, $prev, $rel);
			$sub =~ s/\t//g;
			$l = length($sub);
			
			$c = $l % $tabsize;
			$w -= $c;
			#print "Tab at pos $pos: rel: $rel c: ".($rel % 8)."\n";
			$prev = $pos + $c;
		}
	}
	
	else {
		$w = 75;
	}
	
	$out = substr($in,0,$w);

	print $out.($out =~ /\n$/ ? "" : "\n");
}