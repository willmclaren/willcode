#!/usr/bin/perl

while(<>) {
	chomp;
	next unless $_ =~ /\d+/;
	push @data, $_;
	$total += $_;
}

die "No numerical data found\n" unless scalar @data;

print "Number of datapoints:\t".(scalar @data)."\n";
print "Total:\t\t\t$total\n";

$mean = ($total/(scalar @data));
print "Mean:\t\t\t$mean\n";

# SD
foreach $point(@data) {
	$tot += (($point - $mean)*($point - $mean));
}

$var = $tot / (scalar @data);
$sd = sqrt($var);

print "Variance:\t\t$var\n";
print "Std dev:\t\t$sd\n";


$var = $tot / ((scalar @data)-1);
$sd = sqrt($var);

print "Pop variance:\t\t$var\n";
print "Pop std dev:\t\t$sd\n";

@sorted = sort {$a <=> $b} @data;

$max = $sorted[-1];
$min = $sorted[0];
$size = (scalar @data);
if(isEven($size)) {
	$size = (scalar @data) / 2;
	$median = ($data[$size-1] + $data[$size])/2;
}
else {
	$median = $data[($size - 0.5)];
}

print "Maximum:\t\t$max\n";
print "Minimum:\t\t$min\n";
print "Median:\t\t\t$median\n";
print "Range:\t\t\t".($max - $min)."\n";


sub isEven {
	$a = shift;
	
	return (($a/2) == (int ($a/2)) ? 1 : 0);
}
