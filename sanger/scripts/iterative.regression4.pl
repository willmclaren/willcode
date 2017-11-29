#!/usr/bin/perl

our $file = shift @ARGV;
our %models;

it();

foreach $model(keys %models) {
	print "$model\t$models{$model}\n";
}

sub it() {
	my @list = @_;
	
# 	foreach my $item(@list) {
# 		return 1 unless $item =~ /.+/;
# 	}
	
	#return 1 if scalar @list > 3;
	
	my $name = (scalar @list ? join ".", @list : "all");
	
	my $outfile = "norm.".$name.".reg";
	
	#print "regression.pl @list $file | sort.by.col.pl -r 2 > $outfile\n";
	system("regression.pl hla_drb1 hla_dqb1 @list $file | sort.by.col.pl -r 2 > $outfile");
	
	my $line, $snp, $score;
	my @new = ();
	
	my $handle = newopen($outfile) or die "Could not open file $outfile\n";
	
	$line = <$handle>;
	chomp $line;
	($snp, $score) = split /\t/, $line;
	@new = @list if scalar @list;
	push @new, $snp;
	
	$models{(join "\.", @new)} = $models{(join "\.", @list)} + $score;
	
	it(@new) unless scalar @list >= 6;
	
	close $handle;
	
	return 1;
}


sub newopen {
	my $path = shift;
	local *FH;
	open(FH, $path) or return undef;
	return *FH;
}