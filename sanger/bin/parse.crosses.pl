#!/usr/bin/perl

while(<>) {
	chomp;
	s/^\t//g;
	s/\(//g;
	s/\)//g;
	
	@data = split /\s+/, $_;
	
	if(/^Writing/) {
		$file = $data[2];
		print $file, "\t", (scalar @out ? (join "\n".$file."\t", @out) : "None"), "\n";
		@out = ();
	}
	
	else {
		push @out, (join "\t", ($data[0], $data[1], $data[3], $data[4]));
	}
}

$file = $data[2];
print $file, "\t", (scalar @out ? (join "\n".$file."\t", @out) : "None"), "\n";
@out = ();