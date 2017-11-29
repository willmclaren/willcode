#!/usr/bin/perl

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
my %args_with_vals = (
	'a' => 1,
	'o' => 1,
);

# define a usage message
my $usage = "Usage: perl run.unphase.pl [-w] [-a \"arguments_for_unphase\"] input_dir/\n";

# if no arguments have been given, give a usage message
if(!@ARGV) {
	die $usage;
}

# create a hash to keep arguments in
our %args;

# get the arguments into the hash
while($ARGV[0] =~ /^\-/) {
	my $arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	# give args that don't take a value a nominal value of 1
	my $val = ($args_with_vals{$arg} ? shift @ARGV : 1);
	
	$args{$arg} = $val;
}

$dir = (@ARGV ? shift @ARGV : '.');
opendir DIR, $dir;

@file_list = grep /ped$/, readdir DIR;

# print column headers
print 
	"File\t".
	($args{'a'} =~ /window/ ? "Markers" : "SNP\tChr\tPos").
	"\tLRS\tp-value\t".
	($args{'a'} =~ /window/ ? "Haplotype" : "Allele")."\t".
	'n(case)'."\t".'f(case)'."\t".'n(con)'."\t".'f(con)'."\tOR\n";

foreach $file(@file_list) {
	$file_loc = $dir.($dir =~ /\/$/ ? '/' : '').$file;
	
	die "Could not read from file ".$file_loc."\n" unless -e $file_loc;
	
	# look for a map file
	@bits = split /\./, $file_loc;
	pop @bits;
	
	$map_file = (join '.', @bits).".map";
	if(-e $map_file) {
		open MAP, $map_file;
		
		$marker_num = 1;
		
		while(<MAP>) {
			chomp;
			
			($chr, $snp, $cent, $pos) = split /\s+/, $_;
			
			$map{$marker_num} = "$snp\t$chr\t$pos";
			$marker_num++;
		}
		
		close MAP;
	}
	
	open PIPE,
		# path to unphased binary
		($args{'b'} ? $args{'b'} : "/nfs/team71/psg/wm2/bin/unphased")." ".#/nfs/team71/psg/wm2/Software/unphased/bin/cocaphase")." ".
		
		# add chrX option if the data is for chrX
		($file =~ /x/i ? "-chrX " : " ").
		
		# add user-defined options
		($args{'a'} ? $args{'a'} : "").
		
		# add file
		" ".$dir.$file." |"
	
	or die "Could not run cocaphase command\n";
		
	if($args{'w'}) {
		open OUT, ">".$dir.$file.".out" or die "Could not open output file ".$dir.$file.".out";
	}
	
	while(<PIPE>) {
		print OUT $_ if $args{'w'};
	
		chomp;
		
		next unless /\d/;
		
		if(/marker/i) {
			$marker_num = (split /markers?\s+/, $_)[-1];
			$marker_num =~ s/\s+$//g;
		}
		
		if(/^LRS/) {
			@data = split / /, $_;
			
			$lrs = $data[2];
			$p = $data[-1];
			
			print "$file\t".($map{$marker_num} ? $map{$marker_num} : $marker_num)."\t$lrs\t$p";
			
			# get crap out the way
			$crap = <PIPE>;
			print OUT $crap if $args{'w'};
			$crap = <PIPE>;
			print OUT $crap if $args{'w'};
			
			# now read the allele data
			$read = <PIPE>;
			print OUT $read if $args{'w'};
			
			while($read !~ /^\-+/) {
				@bits = split /\s+/, $read;
				
				print "\t".(join "\t", @bits);
				
				$read = <PIPE>;
				print OUT $read if $args{'w'};
			}
			
			print "\n";
		}
	}
	
	close PIPE;
	close OUT if $args{'w'};
}
