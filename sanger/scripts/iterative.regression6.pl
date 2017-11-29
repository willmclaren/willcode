#!/usr/bin/perl

%args_with_vals = (
	's' => 1,
	'o' => 1,
);

$args{'o'} = "reg";

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


our $file = shift @ARGV;
our %models;

open OUT, ">".$args{'o'}.".debug";

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
	
	my $outfile = $args{'o'}.".".$name.".out";
	
	#print "regression.pl @list $file | sort.by.col.pl -r 2 > $outfile\n";
	system("perl ~/Farm/work/CHD/reg.pl Cohort @list $file | sort.by.col.pl -r 2 > $outfile");
	
	my $line, $snp, $score;
	my @new = ();
	
	my $handle = newopen($outfile) or die "Could not open file $outfile\n";
	
	$line = <$handle>;
	
	print OUT $line;
	
	chomp $line;
	($snp, $score) = split /\t/, $line;
	
	@new = @list if scalar @list;
	push @new, $snp;
	
	$models{(join "\.", @new)} = $models{(join "\.", @list)} + $score;
	
	it(@new) unless ((scalar @list >= 10) || ($score <= 0));
	
	close $handle;
	
	return 1;
}


sub newopen {
	my $path = shift;
	local *FH;
	open(FH, $path) or return undef;
	return *FH;
}