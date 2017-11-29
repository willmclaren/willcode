#!/usr/bin/perl

$args{'c'} = 1;

%args_with_vals = (
	'c' => 1,
);

# process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

$args{'c'}--;


open IN, shift @ARGV;

while(<IN>) {
	chomp;
	
	($from, $from_c, $to, $to_, $well) = split /\t/, $_;
	
	$cohort{$from} = $from_c;
	$cohort{$to} = $to_c;
	
	$switch{$from} = $to;
}

close IN;

foreach $file(@ARGV) {
	open IN, $file;
	open OUTA, ">$file\.to.keep";
	open OUTB, ">$file\.to.move";

	while(<IN>) {
		chomp;
		
		@data = split /\t/, $_;
		
		$sample = $data[$args{'c'}];
		
		if($switch{$sample}) {
		
			$data[$args{'c'}] = $switch{$sample};
			
			if($cohort{$sample} eq $cohort{$switch{$sample}}) {
				print OUTA (join "\t", @data);
				print OUTA "\n";
			}
			
			else {
				print OUTB (join "\t", @data);
				print OUTB "\n";
			}
		}
		
		else {
			print OUTA "$_\n";
		}
	}
	
	close IN;
	close OUTA;
	close OUTB;
}