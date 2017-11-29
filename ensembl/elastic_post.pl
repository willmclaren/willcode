#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

$| = 1;

my $config = {
  url => 'http://bc-29-3-07.internal.sanger.ac.uk:9200/',
  index => 'variation',
  type => 'vep',
  tmpdir => '/tmp',
  batch_size => 1000
};

GetOptions(
  $config,
  'url|u=s',
  'index|i=s',
  'type|t=s',
  'tmpdir|d=s',
  'batch_size|b=i',
  'quiet|q',
);

my $tmpfile = $config->{tmpdir}.'/.'.$$.'_es_in.txt';

open OUT, ">$tmpfile" or die "ERROR: Could not write to tmp file $tmpfile\n";

my $count = 0;

while(<>) {
  printf OUT qq{{ "index" : { "_index" : "%s", "_type" : "%s" }}\n%s}, $config->{index}, $config->{type}, $_;
  
  $count++;
  
  if($count == $config->{batch_size}) {
    close OUT;
    
    my $cmd = sprintf('curl -s -XPOST %s/_bulk --data-binary @%s', $config->{url}, $tmpfile);
    `$cmd`;
    
    print "." unless $config->{quiet};

    open OUT, ">$tmpfile" or die "ERROR: Could not write to tmp file $tmpfile\n";
    
    $count = 0;
  }
}


close OUT;

if($count) {
  my $cmd = sprintf('curl -s -XPOST %s/_bulk --data-binary @%s', $config->{url}, $tmpfile);
  `$cmd`;
}

print "\nDone\n" unless $config->{quiet};
