#!/usr/bin/perl

if(open IN, $ARGV[-1]) {
	$file = pop @ARGV;
	close IN;
}

else {
	$file = "R.input.txt";
}

$num = scalar @ARGV;
$snpstring = ($num ? (join '+', @ARGV).'+' : '')."t1[[indx]]";

$col = 2 + $num;

$prog =<<END;

t1<-read.table("$file",header=TRUE,na.strings="-")
attach(t1)

snpnames<-c(rep("  ",length(t1)-3))

snpdeviance <-c(rep(-9999,length(t1)-3))

counter<-0

cohorts <- levels(Cohort)

for (indx in 4:length(t1)) {
	counter<-counter+1
	snpnames[counter]<-names(t1[indx])
	
	if(length(levels(factor(t1[[indx]]))) >= 2) {
		ok <- 0
		
		for(c in 1:length(cohorts)) {
			temp <- subset(t1, (Cohort == cohorts[c]));
			if(length(levels(factor(temp[[indx]]))) >= 2) {
				ok <- ok + 1
			}
		}
		
		if(ok >= 2) {
	
		#temp <- subset(t1, (snpnames[counter]!="-"))
		
		#if(temp[[indx]][1] != "-") {
			a2<-glm(Transtatus~$snpstring,family=binomial(link=logit),na.action=na.exclude)
			a3<-anova(a2)
			snpdeviance[counter]<-a3[$col,2]
		}
	}
}

complist<-data.frame(snpnames,snpdeviance)

names(complist)<-c("SNP name", "Multivariate Residual Deviance")

write.table(complist, file=".$$.temp",sep="\\t",eol="\\n")


detach("t1")

END

open OUT, ">.$$.temp.prog";
print OUT $prog;
close OUT;

system("/software/R-2.4.0/bin/R CMD BATCH .$$.temp.prog");
open PIPE, qq/cut -f 2,3 .$$.temp | grep -v "Multi" | sed 's\/"\/\/g' |/;

while(<PIPE>) {
	print;
}
