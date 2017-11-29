#!/usr/bin/perl

use strict;

my $arg;
our %args;

while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = 1;
}

our $from = shift @ARGV;
our $to = shift @ARGV;

scan($from);

sub scan {
	my $dir = shift;
	
	print "Scanning $dir\n";
	
	opendir DIR, $dir or die "Could not read directory $dir";
	
	$dir .= '/' unless $dir =~ /\/$/;
	my $to_dir = $dir;
	$to_dir =~ s/$from/$to/;
	$to_dir =~ s/\/\//\//;;
	
	unless(-e $to_dir) {
		print "Making directory $to_dir\n";
		system "mkdir -p $to_dir";
	} 
		
	FILE: foreach my $file(grep !/^\.\.?\z/, readdir DIR) {
		if(opendir TEST, $dir.$file) {
			#print "Directory $dir$file\n";
			
			scan($dir.$file);
		}
		
		else {
			if(-e $to_dir.$file) {
				
				my $date_a = (stat $dir.$file)[9];
				my $date_b = (stat $to_dir.$file)[9];
				
				if($date_a - $date_b > 0) {
					my $size_a = (stat $dir.$file)[7];
					my $size_b = (stat $to_dir.$file)[7];
					
					if($size_a != $size_b) {
						print "Copying $file to $to_dir ... ";
						system "scp $dir$file $to_dir$file";
						print "done\n";
					}
				}
				
				close A;
				close B;
			}
			
			else {
				# ask user to copy this file if it is > 1GB
				if($args{'w'} && (stat $dir.$file)[7] >= 1073741824) {
					print "$file is larger than 1GB - do you want to copy it? : ";
					my $ans = <STDIN>;
					next FILE unless $ans =~ /^y/i;
				}
				
				print "Copying $file to $to_dir ... ";
				system "scp $dir$file $to_dir$file";
				print "done\n";
			}
			
			
		}
	}
	
	closedir DIR;
}


if($args{'s'}) {
	my $temp = $to;
	$to = $from;
	$from = $temp;
	
	scan($to);
}