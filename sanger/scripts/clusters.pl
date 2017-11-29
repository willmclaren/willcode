#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($snp, $chr, $pos) = split /\t/, $_;
	
	$pos{$snp} = $pos;
	$chr{$snp} = $chr;
}

while(<>) {
	($snp, $all, $het, $c, $j, $y, $q) = split /\t/, $_;
	
	next unless $het;
	
	$d{$snp} = $het;
}

$c_num = 1;
$dist = 5000000;

foreach $snp(sort {$chr{$a} <=> $chr{$b} || $pos{$a} <=> $pos{$b}} keys %d) {
	$chr = $chr{$snp};
	$pos = $pos{$snp};
	
	if(($chr == $prev_chr) && ($pos - $prev_pos < $dist)) {
		push @c, $snp;
	}
	
	elsif(@c) {
		#if(($pos{$c[-1]} - $pos{$c[0]} > $dist) && (scalar @c >= 10)) {
			print "$c_num\t$prev_chr\t$c[0]\t$c[-1]\t$pos{$c[0]}\t$pos{$c[-1]}\t".(scalar @c)."\n";
			$c_num++;
		#}
		
		@c = ();
	}
	
	else {
		push @c, $snp;
	}
	
	$prev_pos = $pos;
	$prev_chr = $chr;
}

if(@c) {
	#if(($pos{$c[-1]} - $pos{$c[0]} > $dist) && (scalar @c >= 10)) {
		print "$c_num\t$prev_chr\t$c[0]\t$c[-1]\t$pos{$c[0]}\t$pos{$c[-1]}\t".(scalar @c)."\n";
		$c_num++;
	#}
}