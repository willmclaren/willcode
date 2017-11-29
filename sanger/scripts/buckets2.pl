#!/usr/bin/perl

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($sample, $cat) = split /\t/, $_;
	
	$cat{$sample} = $cat;
}

close IN;



open GOOD, ">good";
open BAD, ">bad";

while(<>) {
	chomp;
	
	($snp, $sample, $geno, $ratio, $plate) = split /\t/, $_;
	
	$ratio{'all'}{$snp} += $ratio;
	$ratio_count{'all'}{$snp}++;
	
	if($cat{$sample} eq 'good') {
		print GOOD "$ratio\n";
	}
	
	elsif($cat{$sample} eq 'bad') {
		print BAD "$ratio\n";
	}
}

close GOOD;
close BAD;


open OUT, ">r.command";

print OUT "good <-read.table(\"good\"); bad <- read.table(\"bad\")\n";
#print OUT "jpeg(filename=\"test.jpg\"); hist(t(good)); str(hist(t(bad))); dev.off()\n";
print OUT
	"jpeg(filename=\"test2.jpg\",quality=100,height=600,width=800);".
	"plot(density(t(good)),col=\"green\",xlab=\"Mahalonobis ratio\",xlim=c(0,1),ylim=c(0,6));".
	"abline(v=mean(t(good)),col=\"green\");".
	"lines(density(t(bad)),col=\"red\"); abline(v=mean(t(bad)),col=\"red\");".
	"dev.off()\n";

close OUT;

system("/software/bin/R --no-restore --no-save --no-readline < r.command");