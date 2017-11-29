while(<>) { chomp; ($s, $a, $b, $c) = split /\t/, $_; $f = ($a+$b+$c > 0 ? ((2*$a)+$b)/(2*($a+$b+$c)) : 0); print "$_\t$f\n";}
