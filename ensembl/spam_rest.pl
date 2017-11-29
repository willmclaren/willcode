#!/usr/bin/env perl

use strict;
use warnings;
 
use HTTP::Tiny;
use Time::HiRes qw/sleep gettimeofday tv_interval/;
 
my $http = HTTP::Tiny->new();
 
my $server = 'http://test.rest.ensembl.org';
my $ext = '/vep/human/region';
my $headers = { 
  'Content-type' => 'application/json',
  'Accept' => 'application/json'
};

my $size = 200;
my @buffer;
my $count = 0;

my $t0 = [gettimeofday];
my $loopt = $t0;

while(<>) {
  next if /^\#/;
  chomp;
  tr/\t/ /;
  push @buffer, sprintf('"%s"', $_);

  if(@buffer == $size) {
    my $response = $http->request('POST', $server.$ext, {
      headers => $headers,
      content => sprintf('{ "variants" : [%s] }', join(',', @buffer))
    });

    if(my $sleep = $response->{headers}->{'Retry-After'}) {
      print STDERR "SLEEPING $sleep\n";
      sleep($sleep);
      $response = $http->request('POST', $server.$ext, {
        headers => $headers,
        content => sprintf('{ "variants" : [%s] }', join(',', @buffer))
      });    
    }

    use Data::Dumper;
    $Data::Dumper::Maxdepth = 3;
    $Data::Dumper::Indent = 1;
    print STDERR Dumper $response unless $response->{success};

    @buffer = ();
    my $now = [gettimeofday];
    my $total_elapsed = tv_interval ( $t0, $now);
    my $elapsed = tv_interval( $loopt, $now);
    $loopt = $now;

    printf STDERR "PING %i %.2f %.2f %.2f\n", $count += $size, $elapsed, $total_elapsed, $count / $total_elapsed;
  }
}
