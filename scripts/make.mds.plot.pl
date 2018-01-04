#!/usr/bin/perl

$args{'s'} = qq/\/lustre\/work1\/sanger\/wm2\/HapMap\/MDS\/wrong.HapMap.cohorts/;
$args{'h'} = 800;
$args{'w'} = 800;
$args{'c'} = "1,2";

%args_with_vals = (
	's' => 1,
	'o' => 1,
	'h' => 1,
	'w' => 1,
	'c' => 1,
	'p' => 1,
	'f' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

($c1,$c2) = split /\,/, $args{'c'};

$high = 0;

# given list of samples to highlight
if($args{'p'}) {
	$args{'p'} =~ tr/\,/\n/;
	
	open OUT, ">.$$.temp.list";
	print OUT $args{'p'}."\n";
	close OUT;
	
	$highfile = ".$$.temp.list";
	$high = 1;
}

elsif(-e $args{'f'}) {
	$highfile = $args{'f'};
	$high = 1;
}


unless(open IN, $args{'s'}) {
	print "WARNING: population label file $args{'s'} not found\n";
	print "Attempting to read from file \"HapMap.cohorts\" ... ";
	$args{'s'} = "HapMap.cohorts";
	
	if(open IN, $args{'s'}) {
		print "success";
		close IN;
	}
	else {
		print "failed - continuing with no population labels";
	}
	
	print "\n";
}

$file = shift @ARGV;
$orig_file = ($args{'o'} ? $args{'o'} : $file);

if($file =~ /\.mds$/) {
# 	open IN, $file;
# 	$head = <IN>;
# 	chomp $head;
# 	@a = split /\s+/, $head;
# 	$last = $a[-1];
# 	close IN;
	

	open PIPE, qq/fix.plink.output.pl $file | cut -f 1-6 | add.info.pl $args{'s'} | fill.blanks.pl | sed 's\/C3\t0\/C3\tSET\/' |/;
	
	open OUT, ">.$$.temp.data";
	while(<PIPE>) {
		s/C3\t0/C3\tSET/;
		s/\t0$/\tZ/ if $args{'z'};
		print OUT;
	}
	close PIPE;
	close OUT;
	
	$file = ".$$.temp.data";
}


# 3d plot?
if($args{'3'}) {
	$plot = "scatterplot3d";
	$points_a = "d\$C1, d\$C2, d\$C3";
	$points_b = "scatterplot3d(temp\$C1, temp\$C2, temp\$C3, color=i, pch=i, type=\"p\")";
	$lib = "library\(scatterplot3d\)";
}

else {
	$plot = "plot";
	$points_a = "d\$C$c1, d\$C$c2";
	$points_b = "points(temp\$C$c1, temp\$C$c2, col=i, pch=i)";
}


# legend on right?
if($args{'r'}) {
	$leg = "max(d\$C$c1)-0.25*(max(d\$C$c1)-min(d\$C$c1))";
}

else {
	$leg = "min(d\$C$c1)+0.01*(max(d\$C$c1)-min(d\$C$c1))";
}

$prog =<<END;
# load package for scatterplot3d if required
$lib

# read in the data
d <- read.table("$file",header=T);

# get list of populations (sets)
sets <- names(table(d\$SET));

# open JPEG file to write to
jpeg(filename="$orig_file.jpg",width=$args{'w'},height=$args{'h'},quality=100);

# draw blank plot
$plot($points_a,type="n");

# iterate thru populations
for(i in 1:length(sets)) {

	# subset the pop
	temp <- subset(d, d\$SET==sets[i]);
	
	# points command dependent on whether doing 3D or not
	$points_b;
}

# do highlighting
if($high) {
	
	high <- read.table("$highfile");
	a <- names(table(high));
	
	for(i in 1:length(a)) {
		temp <- subset(d, d\$FID==a[i]);
		
		points(temp\$C$c1, temp\$C$c2, col=i, pch=1, cex=1.5);
		points(temp\$C$c1, temp\$C$c2, col=i, pch=1, cex=2);
		
		#print(temp);
	}
}

# add figure legend
legend($leg, max(d\$C$c2)-0.01*(max(d\$C$c2)-min(d\$C$c2)), sets, col=(1:length(sets)), pch=(1:length(sets)));

# close the JPEG file
dev.off();

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
	print "Completed successfully - wrote to image file $orig_file\.jpg\n";
}