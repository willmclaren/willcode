#!/usr/bin/perl

use lib '/nfs/team71/psg/wm2/Perl';

use Statistics::Basic::Correlation;



# read in the file containing r2 values
open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	next if /^\#/;
	next if /Best/;
	next unless /\s+/;
	next if /\,/;
	
	($a, $b, $r) = split /\s+/, $_;
	
	next if $a eq $b;
	
	$r{$a}{$b} = $r;
	$r{$b}{$a} = $r;
}

close IN;



while(<>) {
	chomp;
	
	($snp, $p) = split /\s+/, $_;
	
	$snps{$snp} = -(log($p)/log(10));
}

@list = qw/rs13119723 rs6822844 rs13151961 rs12642902 rs6840978 rs11938795 rs11734090 rs7684187 rs975405 rs7678445 rs1398553 rs1127348 rs4374642 rs2893008 rs4288027 rs6848139 rs7699742 rs10857092 rs716501 rs7683061 rs7682241 rs4505848 rs6835946 rs11732095 rs17005931 rs6852535 rs4492018/;

foreach $linked(keys %r) {
	next if $snps{$linked};
	
	@p = ();
	@r = ();
	$max = 0;
	
	foreach $snp(keys %snps) {
		#next unless $r{$linked}{$snp};
		push @p, $snps{$snp};
		push @r, $r{$linked}{$snp};
		
		$max = $r{$linked}{$snp} if $r{$linked}{$snp} > $max;
	}
	
	next unless $max > 0;
	
	$c = new Statistics::Basic::Correlation(\@p, \@r);
	$corr = $c->query;
	
	@r = sort {$a <=> $b} @r;
	
	$m = new Statistics::Basic::Mean(\@r);
	$mean = $m->query;
	
	$min = $r[0];
	$max = $r[-1];

	
	print "$linked\t$corr\t$mean\t$min\t$max";
	
	foreach $snp(@list) {
		print "\t$snp\t$r{$linked}{$snp}";
	}
	
	print "\n";
}