#!/usr/bin/perl


#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$temp = shift @ARGV;
$target = shift @ARGV;
$chr = shift @ARGV;

$prog =<<END;


template <- "$temp"
target <- "$target"
# chip <- ""

# frq <- read.table(paste(target, ".snp.list", sep=""),
#                   header=F)
# dim(frq)
# #frq <- frq[frq\$MAF >= 0.05, ] #common
# dim(frq)
# snpinchip <- read.table(paste("../", chip, ".list", sep=""), header=F)[[1]]
# frq <- frq[!(frq\$SNP \%in\% snpinchip), ] #not in chip
# dim(frq)

list <- read.table(paste("not", target, ".snp.list", sep=""), header=F, colClasses=c("character"))
#list <- read.table("temp", header=F, colClasses=c("character"))

for (chrm in c($chr)) { #loop for chrm BEGIN

print(paste("chrm", chrm))

genotyped <- read.table(paste("58C", target, ".chr", chrm, ".bgl", sep=""), header=F)
#dim(genotyped)

phased <- read.table(paste(template, ".58C", target, ".chr", chrm, ".bgl", sep=""), header=F)
#dim(phased)
#phased <- phased[ ,-c(2 + 1:(dim(phased)[2] - dim(genotyped)[2]))]
#dim(phased)
# 
output <- list[,1]
# dim(output)

corv <- numeric()
for (i in 1:length(list[,1])) {
snp <- list[i,1]
print(snp)
#
g <- unlist(lapply(genotyped[genotyped\$V2 == as.character(snp), -c(1:2)],
                   as.character))
g[g=="0"] <- NA

g[g=="A"] <- 1
g[g=="C"] <- 2
g[g=="G"] <- 3
g[g=="T"] <- 4
g[g=="N"] <- NA

if(length(g) > 10) {

	alphabets <- union(g, list()) #based on genotype
	g[g==alphabets[1]] <- 0
	g[g==alphabets[2]] <- 1
	g <- as.numeric(g)
	
	#print(head(g))
	
	g <- g[2 * (1:(length(g)/2))] + g[-1 + 2 * (1:(length(g)/2))]
	#
	p <- unlist(lapply(phased[phased\$V2 == as.character(snp), -c(1:2)],
					as.character))
					
	if(length(p) > 10) {
		p[p=="0"] <- NA
		p[p=="N"] <- NA
		p[p=="A"] <- 1
		p[p=="C"] <- 2
		p[p=="G"] <- 3
		p[p=="T"] <- 4
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
	
	else {
		corv <- c(corv, -9)
	}
}

else {
	corv <- c(corv, -9)
}
}

output <- cbind(output, corv)
#names(output)[7] <- "r2"

write.table(output,
            paste(template, ".58C", target, ".chr", chrm, ".r2", sep=""),
            row.names=F, col.names=T, quote=F, sep="	")

} #loop for chrm END

#plot(output$MAF, output$r2)
#plot(factor(floor(output$MAF * 20) / 20), output$r2)
#plot(sort(output$r2))

END




# write the R program to a temporary file
open OUT, ">.$$.temp.prog";
print OUT $prog;
close OUT;

# look for R in /software/
if(-e "/software/R-2.6.0/bin/R") {
	system("/software/R-2.6.0/bin/R CMD BATCH .$$.temp.prog");
	print "/software/R-2.6.0/bin/R CMD BATCH .$$.temp.prog\n" if $args{'d'};
}

# otherwise just hope it's in the path
else {
	system("R CMD BATCH .$$.temp.prog");
	print "R CMD BATCH .$$.temp.prog\n" if $args{'d'};
}


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
	
	die "\nEnd of errors\n" if $print;
}

if(!$print) {
	print "Completed successfully\n";
}


# delete temporary files unless we're debugging
system("rm .$$.*") unless $args{'d'};