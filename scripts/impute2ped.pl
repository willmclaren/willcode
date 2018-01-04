#!/usr/bin/perl

%args_with_vals = (
	't' => 1,
);

$args{'t'} = 0.9;

# process the flags
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-+//g;
	
	# get the next element from the array if this flag is meant to be followed by a value
	$val = ($args_with_vals{$arg} ? shift @ARGV : 1);
	
	$args{$arg} = $val;
}

open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	push @samples, (split /\s+/, $_)[0];
}

close IN;


while(<>) {
	chomp;
	
	@data = split /\s+/, $_;
	
	shift @data;
	
	$snp = shift @data;
	$pos = shift @data;
	
	push @snps, $snp;
	
	$a = (shift @data);
	$b = (shift @data);
	
	$s = 0;
	
	while(@data) {
		%p = ();
		
		$p{$a.$a} = shift @data;
		$p{$a.$b} = shift @data;
		$p{$b.$b} = shift @data;
		
		$val = -1;
		$best = "NN";
		
		foreach $g(keys %p) {
			#print "$snp\tCheese\t$g\t$p{$g}\n";
		
			if($p{$g} > $val) {
				$best = $g;
				$val = $p{$g};
			}
		}
		
# 		$best = (sort {$p{$a} <=> $p{$b}} keys %p)[-1];
# 		$val = (sort {$a <=> $b} values %p)[-1];
		
		#print "$snp\t$s\t$best\t$val\t".(join " ", values %p)."\n";
		
		push @{$data{$s}}, ($val >= $args{'t'} ? $best : "NN");
		
		$s++;
	}
}


for $s(0..$#samples) {
	print "$samples[$s]\t1\t0\t0\t0\t0";
	
	for $p(0..$#snps) {
		$g = $data{$s}[$p];
		
		$g = join " ", (split //, $g);
		
		print "\t$g";
	}
	
	print "\n";
}