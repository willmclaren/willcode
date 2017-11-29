#!/usr/bin/perl

@cols = qw/chr nice snpa snpb from to count/;

while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	
	$sample = shift @data;
	$num = shift @data;
	
	foreach $col(@cols) {
		$data{$sample}{$num}{$col} = shift @data;
	}
}


foreach $sample(keys %data) {
	
	$total_length = 0;
	$total_count = 0;
	$num = 0;
	
	@lengths = ();

	foreach $c(keys %{$data{$sample}}) {
		$total_length += $data{$sample}{$c}{'to'} - $data{$sample}{$c}{'from'};
		$total_count += $data{$sample}{$c}{'count'};
		$num++;
		
		#push @lengths, ($data{$sample}{$c}{'to'} - $data{$sample}{$c}{'from'});
	}
	
	$mean_length = $total_length / ($num * 1000000);
	$mean_density = ($total_count * 1000000) / $total_length;
	
	print "$sample\t$num\t$total_length\t$total_count\t$mean_length\t$mean_density\n";
}