#!/usr/bin/perl

use strict;
use warnings;

$| = 1;

use Getopt::Long;
use Pod::Usage;

my $config = {};

# parse command line
GetOptions(
  $config,

  # displays help message
  'help|h',
  
  # variables a-g
  (map {$_.'=s'} ("a".."g")),

  # or provide list
  'list|l=s',

  # or manual entry
  'manual|m',

  # 0-pad
  'pad|p=i',
);

pod2usage(1) if $config->{help} or !@ARGV;

run_reps($config, join(" ", @ARGV), get_reps($config));

sub get_reps {
  my $config = shift;

  my @reps;
  my @letters = "a".."z";

  if(my $file = $config->{list}) {
    open IN, $file or die "Could not read from list file $file: $!\n";
    while(<IN>) {
      chomp;
      my @bits = split("\t", $_);

      my %rep = map { ($letters[$_] x 3) => $bits[$_] } (0..$#bits);
      
      push @reps, \%rep;
    }
    close IN;
  }

  foreach my $letter(grep {defined($config->{$_})} @letters) {
    my $n = 0;

    # deal with e.g. 1-10,12,14-17
    foreach my $val(split /\,/, $config->{$letter}) {
      my @nnn = split /\-/, $val;
      die("ERROR: Incorrect format \"$val\"\n") if @nnn > 2;
      
      for my $a($nnn[0]..$nnn[-1]) {
        $reps[$n]->{$letter x 3} = $a;
        $n++;
      }
    }
  }

  return \@reps;
}

sub run_reps {
  my ($config, $command, $reps) = @_;

  # record which variable names we need to use
  my %vars;
  foreach my $letter("a".."z") {
    my $var = $letter x 3;  
    $vars{$var} = 1 if $command =~ /$var/;
  }

  my $have_reps = scalar @$reps;

  die("ERROR: No variables or valid options provided\n") unless $have_reps || $config->{manual};

  # tell the user what we're assuming the command to be (debug)
  print STDERR "Command to be run: $command\n\n";

  # set up a loop to go through each of the sets/repeats
  while(1) {

    my $rep = {};

    if(@$reps) {
      $rep = shift @$reps;
    }
    
    # enter values manually via STDIN
    # NB user has to manually CTRL-C out of the script in this method
    elsif($config->{manual}) {
      foreach my $var(sort keys %vars) {
        print "Value for $var: ";
        $rep->{$var} = <STDIN>;
        chomp $rep->{$var};
      }
    }
    
    # copy the command string so we can sed it
    my $ex = $command;
    
    # do the sed-ing substitution for each variable
    foreach my $var(keys %$rep) {
      if($config->{pad} && $rep->{$var} =~ /\d+/) {
        my $v = $rep->{$var};
        
        while(length($v) < $config->{pad}) {
          $v = "0".$v;
        }
        
        $rep->{$var} = $v;
      }

      my $val = $rep->{$var};
    
      $ex =~ s/$var/$val/g;
    }
    
    # print out the command we're about to run
    print STDERR "Executing command: $ex\n";
    
    # run the command using the fancy ` thing - allows us to get back the output directly from the command
    open CMD, "$ex |";
    while(<CMD>) {
      print $_;
    }
    
    # confirm it finished and print the output (if there was any)
    print STDERR "done\n\n";

    last if $have_reps && scalar @$reps == 0;
  }
}

__END__

=head1 NAME

repeat.command.pl

=head1 SYNOPSIS

repeat.command.pl [options] [command]

=head1 OPTIONS

=over 8

=item B<-a, -b, -c ... -g>

Give a value or list of values to substitute in for e.g. "aaa" in
the command. Can be a comma-separated list, and include ranges
e.g. 1-10

=item B<--list|-l>

Specify a file with variable substitutions. Each line in the
file corresponds to one iteration of executing the command.
The list file should be tab-delimited; each column corresponds
in turn to "aaa", "bbb" etc.

=item B<--manual|-m>

Enter values manually when prompted for each loop.

=item B<--pad>

0-pad numerical values.

=back

=head1 DESCRIPTION

B<repeat.command.pl> repeats the given command substituting
in values for the variables given as e.g. "aaa", "bbb".

=cut