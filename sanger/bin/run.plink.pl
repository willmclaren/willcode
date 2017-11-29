#!/usr/bin/perl

# DEAL WITH ARGUMENTS
#####################

# define a list of arguments that have values to shift
my %args_with_vals = (
	'a' => 1,
	'o' => 1,
	'out' => 1,
);

# define a usage message
my $usage = "Usage: perl run.plink.pl [-b path_to_plink_binary] [-o output_stem] [-a \"arguments_for_plink\"] input_dir/\n";

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

$args{'o'} = $args{'out'} if $args{'out'};

# set default stem
$args{'o'} = "default" unless $args{'o'};


$dir = (@ARGV ? shift @ARGV : '.');
opendir DIR, $dir;

@file_list = grep /ped$/, readdir DIR;

$first = 1;

foreach $file(@file_list) {
	$file_loc = $dir.($dir =~ /\/$/ ? '/' : '').$file;
	
	die "Could not find file ".$file_loc."\n" unless -e $file_loc;
	
	@bits = split /\./, $file_loc;
	pop @bits;
	$stem = join '.', @bits;
	$map_file = $stem.".map";
	
	die "Could not find map file ".$map_file."\n" unless -e $map_file;
	
	open MAP, $map_file;
	
	%map = ();
		
	while(<MAP>) {
		chomp;
		
		($chr, $snp, $cent, $pos) = split /\s+/, $_;
		
		$map{$snp} = $pos;
	}
	
	close MAP;
	
	# run plink
	system(
		# path to executable
		($args{'b'} ? $args{'b'} : 'plink').
		
		# no web option
		" --noweb ".
		
		# custom options
		$args{'a'}.
		
		# path to data
		" --file ".$stem.
		
		# write to log
		" >>".$args{'o'}.".log"
	);
	
	print "Running ".# path to executable
		($args{'b'} ? $args{'b'} : 'plink').
		
		# no web option
		" --noweb ".
		
		# custom options
		$args{'a'}.
		
		# path to data
		" --file ".$stem.
		
		# write to log
		" >>".$args{'o'}.".log"."\n";
	
	
	# now deal with the files that were generated
	
	# get assoc file	
	if($args{'a'} =~ /assoc/ && -e 'plink.assoc') {
		open IN, 'plink.assoc';
		
		$outfile = $args{'o'}.($args{'o'} =~ /\/$/ ? '/' : '').".assoc";
		
		open OUT, ">>".$outfile or die "Could not write to output file ".$outfile."\n";
	}
		
	# get model file
	if($args{'a'} =~ /model/ && -e 'plink.model') {
		open IN, 'plink.model';
		
		$outfile = $args{'o'}.($args{'o'} =~ /\/$/ ? '/' : '').".model";
		
		open OUT, ">>".$outfile or die "Could not write to output file ".$outfile."\n";
	}
		
	LINE: while(<IN>) {
	
		# get rid of leading whitespace
		$_ =~ s/^\s+//g;
		
		chomp;
		
		# deal with header line
		if(/CHR.+SNP.+/) {
			
			# only print out the header line if this it the first run in this batch
			if($first) {
				@data = split /\s+/, $_;
				$crap = shift @data;
				$crap = shift @data;
				
				print OUT "SNP\tCHR\tCOORD\t".(join "\t", @data)."\n";
				
				$first = 0;
			}
			
			else {
				next LINE;
			}
		}
		
		# deal with the data
		else {
			@data = split /\s+/, $_;
			
			$chr = shift @data;
			$snp = shift @data;
			
			# add the map data
			print OUT "$snp\t$chr\t$map{$snp}\t";
			
			# now print out the rest
			print OUT (join "\t", @data)."\n";
		}
	}
	
	close OUT;
	close IN;
}
