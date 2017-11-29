#!/usr/bin/perl

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$template = shift @ARGV or die "No template population specified\n";
$target = shift @ARGV or die "No target population specified\n";

$prog =<<END;

template <- "$template"
target <- "$target"
chip <- "1M"

frq <- read.table(paste("Fumi/", target, ".frq", sep=""),
                  header=T)
dim(frq)
#frq <- frq[frq\$MAF >= 0.05, ] #common
dim(frq)
snpinchip <- read.table(paste("Fumi/../", chip, ".list", sep=""), header=F)[[1]]
frq <- frq[!(frq\$SNP %in% snpinchip), ] #not in chip
dim(frq)


for (chrm in c(21)) { #loop for chrm BEGIN

print(paste("chrm", chrm))

genotyped <- read.table(paste(target, ".chrm", chrm, ".bgl", sep=""),
                        header=F)
dim(genotyped)

phased <- read.table(paste(template, ".", target, "_", chip, "_fp_chr", chrm, ".bgl", sep=""),
                        header=F)
dim(phased)
phased <- phased[ ,-c(2 + 1:(dim(phased)[2] - dim(genotyped)[2]))]
dim(phased)

output <- frq[frq\$SNP %in% intersect(genotyped\$V2, phased\$V2), ]
dim(output)

corv <- numeric()
for (snp in as.character(output\$SNP)) {
#print(snp)
#
g <- unlist(lapply(genotyped[genotyped\$V2 == as.character(snp), -c(1:2)],
                   as.character))
g[g=="0"] <- NA
alphabets <- union(g, list()) #based on genotype
g[g==alphabets[1]] <- 0
g[g==alphabets[2]] <- 1
g <- as.numeric(g)
g <- g[2 * (1:(length(g)/2))] + g[-1 + 2 * (1:(length(g)/2))]
#
p <- unlist(lapply(phased[phased\$V2 == as.character(snp), -c(1:2)],
                   as.character))
p[p=="0"] <- NA
p[p==alphabets[1]] <- 0
p[p==alphabets[2]] <- 1
p <- as.numeric(p)
p <- p[2 * (1:(length(p)/2))] + p[-1 + 2 * (1:(length(p)/2))]
#
if (length(union(p, list()))==1) {
  corv <- c(corv, 0)
} else {
  corv <- c(corv, cor(g, p, use = "complete"))
}
}

output <- cbind(output, corv)
names(output)[7] <- "r2"

write.table(output,
            paste(template, ".", target, "_", chip, ".chrm", chrm, ".test.r2", sep=""),
            row.names=F, col.names=T, quote=F, sep="\t")

} #loop for chrm END

#plot(output\$MAF, output\$r2)
#plot(factor(floor(output\$MAF * 20) / 20), output\$r2)
#plot(sort(output\$r2))

END




# write the R program to a temporary file
open OUT, ">.$$.temp.prog";
print OUT $prog;
close OUT;

# look for R in /software/
if(-e "/software/R-2.5.1/bin/R") {
	system("/software/R-2.5.1/bin/R CMD BATCH .$$.temp.prog");
	print "/software/R-2.5.1/bin/R CMD BATCH .$$.temp.prog\n" if $args{'d'};
}

# otherwise just hope it's in the path
else {
	system("R CMD BATCH .$$.temp.prog");
	print "R CMD BATCH .$$.temp.prog\n" if $args{'d'};
}

# delete temporary files unless we're debugging
system("rm .$$.*") unless $args{'d'};

# check for errors
open IN, ".$$.temp.prog.Rout";

$print = 0;

while(<IN>) {
	if(/^Error/) {
		print "ERROR: problems encountered in R. Debug follows:\n\n";
		print $buf.$_;
		$print = 1;
	}
	
	elsif($print) {
		print;
	}
	
	else {
		$buf = $_;
	}
}

if(!$print) {
	print "Completed successfully\n";
}