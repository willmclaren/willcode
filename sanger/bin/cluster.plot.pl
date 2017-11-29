#!/usr/bin/perl

%args_with_vals = (
	'o' => 1,
	'h' => 1,
);

# process arguments from command line
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$h = 0;
if(open IN, $args{'h'}) {
	$high = $args{'h'};
	$h = 1;
}

if(open IN, $ARGV[-1]) {
	$file = pop @ARGV;
	close IN;
}

else {
	$file = "R.input.txt";
}

$outstem = ($args{'o'} ? $args{'o'} : "R.output");


$prog =<<END;

all <- read.table("$file",header=T)
attach(all)

snps <- levels(SNP)
alleles <- names(table(all\$Call))

if($h) {
	high <- read.table("$high",header=T);
}

for (snpnum in 1:length(snps)) {
	snp <- snps[snpnum]
	
	temp <- all[SNP == snp,]
	
	jpeg(filename=paste("$outstem",".",snp,".jpg",sep=""),quality=100,width=600,height=650)
	
	list <- c()
	
	for(a in 1:length(alleles)) {
		temp2 <- temp[temp\$Call == alleles[a],]
		
		if(length(temp2[,1])>0) {
			list <- c(list, alleles[a])
		}
	}
	
	a <- 1
	allele <- list[a]
	temp2 <- temp[temp\$Call == allele,]
	
	plot(xlim = c(min(temp\$Height_a),max(temp\$Height_a)), ylim = c(min(temp\$Height_b),max(temp\$Height_b)), temp2\$Height_a, temp2\$Height_b,xlab=temp\$Allele_a[1],ylab=temp\$Allele_b[1],pch=a,col=a,main=snp,cex=0.75)
		
	for(a in 2:length(list)) {
		allele <- list[a]
		temp2 <- temp[temp\$Call == allele,]
		
		if(length(temp2[,1])>0) {
			points(temp2\$Height_a, temp2\$Height_b,pch=a,col=a,cex=0.75)
		}
	}
	
	legend(max(temp\$Height_a)-0.1*(max(temp\$Height_a)-min(temp\$Height_a)), max(temp\$Height_b)-0.01*(max(temp\$Height_b)-min(temp\$Height_b)), list,col=(1:length(list)), pch=(1:length(list)),cex=0.75)
	
	if($h) {
		temphigh <- high[high$SNP == snp,]
		
		points(temphigh\$Height_a, temphigh\$Height_b, pch=1, col=5, cex=2.5)
	}
	
# 	if($h) {
# 		
# # 		temp3 <- temp[temp\$Sample == high\$Sample[1],];
# # 		points(temp3\$Height_a, temp3\$Height_b, pch=1, col=5, cex=2.5);
# 		
# 		for(i in 1:length(high)) {
# 			temp3 <- temp[temp\$Sample == high\$Sample[i],];
# 			points(temp3\$Height_a, temp3\$Height_b, pch=1, col=5, cex=2.5);
# 		}
# 	}
	
	dev.off()
}

detach("all")

END

open OUT, ">.$$.temp.prog";
print OUT $prog;
close OUT;

system("R CMD BATCH .$$.temp.prog");

print "ID used: $$\n";

# check for errors
open IN, ".$$.temp.prog.Rout";
$p = 0;

while(<IN>) {
	$p = 1 if /error/i;
	print if $p;
}
close IN;