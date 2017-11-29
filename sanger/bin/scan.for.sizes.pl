#!/usr/bin/perl

use strict;

my $arg;
our %args;

my %args_with_vals = (
	's' => 1,
	'o' => 1,
	'h' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}

our $from = shift @ARGV;

scan($from);

sub scan {
	my $dir = shift;
	
	#print "Scanning $dir\n";
	
	opendir DIR, $dir or die "Could not read directory $dir";
	
	$dir .= '/' unless $dir =~ /\/$/;
		
	FILE: foreach my $file(grep !/^\.\.?\z/, readdir DIR) {
		if(opendir TEST, $dir.$file) {
			scan($dir.$file);
		}
		
		else {
			my $size_a = (stat $dir.$file)[7];
			
			if($size_a >= ($args{'s'} ? $args{'s'} : 1073741824)) {
				print "$dir$file\t$size_a\n";
			}
		}
	}
	
	closedir DIR;
}