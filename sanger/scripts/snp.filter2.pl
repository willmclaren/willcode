#!/usr/bin/perl

# define columns
@cols = qw/chr pos chia pa chig pg hwe maf cr/;

# set thresholds
$cr = 92;
$hwe = 0.001;
$maf = 0.01;
$maf_cr = 98;
$cluster = 100000;
$good_p = 0.05;
$all_p = 0.001;

# read in data
while(<>) {
	chomp;
	
	@data = split /\t/, $_;
	$snp = shift @data;
	
	foreach $col(@cols) {
		$data{$snp}{$col} = shift @data;
	}
}

count(\%data, 'start');

# WTCCC criteria
# filter(\%data, 'cr', $cr); count(\%data, 'CR');
# filter(\%data, 'hwe', $hwe); count(\%data, 'HWE');
# foreach $snp(keys %data) {
# 	#next if $data{$snp}{$col} !~ /\d+/;
# 	delete $data{$snp} if (($data{$snp}{'maf'} < $maf) && ($data{$snp}{'cr'} < $maf_cr));
# } count(\%data, 'MAF');

# p-value filtering
# filter(\%data, 'pa', $all_p, 1); count(\%data, 'all p-val');
# filter(\%data, 'pg', $good_p, 1); count(\%data, 'good p-val');

# cluster filtering
$prev_chr = 0;
$prev_pos = 0;
$prev_snp = 0;

$clus = 1;

# copy data
%backup = %data;

foreach $snp(sort {$data{$a}{'chr'} <=> $data{$b}{'chr'} || $data{$a}{'pos'} <=> $data{$b}{'pos'}} keys %data) {
	if(($data{$snp}{'chr'} eq $prev_chr) && ($data{$snp}{'pos'} - $prev_pos <= $cluster)) {
		push @cluster, $prev_snp unless scalar @cluster;
		push @cluster, $snp;
	}
	
	elsif(scalar @cluster) {
		@list = sort {$data{$a}{'cr'} <=> $data{$b}{'cr'}} @cluster;
		
		%best = ();
		
		$clus--;
	
		if(scalar @cluster <= 3) {
			$best{$list[-1]} = 1;
		}
		
		else {
			$best{$list[-1]} = 1;
			$best{$list[-2]} = 1;
		}
		
		foreach $snpa(@cluster) {
			delete $data{$snpa} unless $best{$snpa};
		}
		
		foreach $snpa(@cluster) {
			$cluster{$snpa} = $clus;
		}
		
		@cluster = ();
		
		$clus++;
		$cluster{$snp} = $clus;
		$clus++;
	}
	
	else {
		$cluster{$snp} = $clus;
		$clus++;
	}
	
	$prev_chr = $data{$snp}{'chr'};
	$prev_pos = $data{$snp}{'pos'};
	$prev_snp = $snp;
}

count(\%data, 'clustering');

open OUT, ">temp2";

foreach $snp(sort {$data{$a}{'chr'} <=> $data{$b}{'chr'} || $data{$a}{'pos'} <=> $data{$b}{'pos'}} keys %data) {
	print OUT $snp;
	
	foreach $col(@cols) {
		print OUT "\t$data{$snp}{$col}";
	}
	
	print OUT "\t$cluster{$snp}";
	
	print OUT "\n";
}

close OUT;

open OUT, ">temp3";

foreach $snp(sort {$backup{$a}{'chr'} <=> $backup{$b}{'chr'} || $backup{$a}{'pos'} <=> $backup{$b}{'pos'}} keys %backup) {
	print OUT $snp;
	
	foreach $col(@cols) {
		print OUT "\t$backup{$snp}{$col}";
	}
	
	print OUT "\t$cluster{$snp}";
	
	print OUT "\n";
}

close OUT;


sub filter() {
	my ($data, $col, $val) = @_;
	my $gt = 0;
	$gt = 1 if scalar @_ > 3;
	
	#print "$gt\n";
	
	foreach my $snp(keys %$data) {
		#next if $data->{$snp}{$col} !~ /\d+/;
		
		if($data->{$snp}{$col} !~ /\d+/) {
			delete $data->{$snp} unless $data->{$snp}{$col} =~ /\d+/;
			next;
		}
	
		if($gt) {
			#print "$snp $col $data->{$snp}{$col}\n" if $data->{$snp}{$col} > $val;
			delete $data->{$snp} if $data->{$snp}{$col} > $val;
		}
		
		else {
			#print "$snp $col $data->{$snp}{$col}\n" if $data->{$snp}{$col} < $val;
			delete $data->{$snp} if $data->{$snp}{$col} < $val;
		}
	}
}

sub count() {
	my $data = shift;
	print "Leaves ".(scalar keys %$data)." SNPs".(@_ ? " after ".(shift @_) : "")."\n";
}