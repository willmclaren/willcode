#!/usr/bin/perl

$sample = shift @ARGV;

system qq/echo $sample \| cat \- outliers \> Output\/l$sample/;

for $i(20..22) {
	system qq/list.grep.pl -v Output\/l$sample ..\/chr$i.ped \| perl \~\/scripts\/comp.ld.pl -d ..\/chr$i\.map \- > Output\/$sample.chr$i\.LD/;
}
