#!/usr/bin/perl

%args_with_vals = (
	'c' => 1,
	'd' => 1,
);

$args{'c'} = 1;
$args{'d'} = "\t";

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$args{'c'}--;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$id = shift @data;
	
	$count = scalar @data;
	
	$line{$id} = join "\t", @data;
}

close IN;



while(<>) {
	chomp;
	
	@data = split /$args{'d'}/, $_;
	
	$id = $data[0];
	
	if(exists $line{$id}) {
		@line = split /\t/, $line{$id};
			
		for $i($args{'c'}..(($args{'c'} + $count)-1)) {
			$data[$i] = shift @line;
		}
		
		print (join $args{'d'}, @data);
		print "\n";
	}
	
	else {
		print "$_\n";
	}
}