#!/usr/bin/perl

$snps = shift @ARGV;
$ped = shift @ARGV;

it();

sub it() {
	my @list = @_;
	
	my $name = (scalar @list ? join ".", @list : "all");
	
	my $outfile = $name.".mytdt";
	
	print "tdt.pl ".(@list ? "-s ".(join ",", @list) : "")." $snps $ped | sort.by.col.pl 6 > $outfile\n";
	system("tdt.pl ".(@list ? "-s ".(join ",", @list) : "")." $snps $ped | sort.by.col.pl 6 > $outfile\n");
	
	my $line, @line;
	my @new = ();
	
	open IN, $outfile or die "Could not open $outfile\n";
	
	$line = <IN>;
	close IN;
	chomp $line;
	@line = split /\t/, $line;
	@new = @list if scalar @list;
	push @new, $line[0];
	
	#print "@new\n";
	
	it(@new) unless scalar @list >= 3;
	
	return 1;
}


sub newopen {
	my $path = shift;
	local *FH;
	open(FH, $path) or return undef;
	return *FH;
}