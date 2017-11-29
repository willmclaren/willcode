#!/usr/bin/perl
# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


use strict;

use Getopt::Long;
use FileHandle;
use File::Path qw(make_path);
use Storable qw(nstore_fd);
use Scalar::Util qw(weaken);

use Bio::EnsEMBL::CoordSystem;
use Bio::EnsEMBL::Slice;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Translation;
use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);
use Bio::EnsEMBL::Variation::Utils::VariationEffect qw(overlap);
use Bio::DB::Fasta;
use Bio::EnsEMBL::Registry;

our $VERSION = 81;


# set defaults
my $config = {
  # db opts
  host              => 'ensembldb.ensembl.org',
  port              => 3306,
  user              => 'anonymous',
  password          => undef,
  species           => 'homo_sapiens'
};

my $count_args = scalar @ARGV;

GetOptions(
  $config,
  'input|i|gtf|gff|g=s',
  'fasta|f=s',
  'output=s',
  'help',
) or die "ERROR: Failed to parse command line options\n";

if(defined($config->{help}) || !$count_args) {
  usage();
  exit(0);
}

# check for errors
die "ERROR: No FASTA file/directory specified\n" unless defined($config->{fasta});


$config->{dir} .= $config->{species}.'/'.$config->{db_version};

if(defined($config->{fasta})) {
  die "ERROR: Specified FASTA file/directory not found" unless -e $config->{fasta};
  
  debug("Checking/creating FASTA index");

  # check lock file
  my $lock_file = $config->{fasta};
  $lock_file .= -d $config->{fasta} ? '/.vep.lock' : '.vep.lock';
  
  # lock file exists, indexing failed
  if(-e $lock_file) {
    for(qw(.fai .index .vep.lock)) {
      unlink($config->{fasta}.$_) if -e $config->{fasta}.$_;
    }
  }
  
  # create lock file
  open LOCK, ">$lock_file" or die("ERROR: Could not write to FASTA lock file $lock_file\n");
  print LOCK "1\n";
  close LOCK;
  
  # run indexing
  $config->{fasta_db} = Bio::DB::Fasta->new($config->{fasta});
  
  # remove lock file
  unlink($lock_file);
}

# create a coord system
$config->{coord_system} = Bio::EnsEMBL::CoordSystem->new(
  -NAME => 'chromosome',
  -RANK => 1,
);

# read synonyms from file if given
read_synonyms_file($config) if $config->{synonyms};

my @fields = qw(seqname source feature start end score strand frame attributes comments);
my $line_num = 0;
$config->{dbID} = 1;
my ($prev_chr, $by_region);
my $in_file_handle = new FileHandle;

if(defined($config->{input})) {
  
  # check defined input file exists
  die("ERROR: Could not find input file ", $config->{input}, "\n") unless -e $config->{input};
  
  if($config->{input} =~ /\.gz$/){
    $in_file_handle->open($config->{compress}." ". $config->{input} . " | " ) or die("ERROR: Could not read from input file ", $config->{input_file}, "\n");
  }
  else {
    $in_file_handle->open( $config->{input} ) or die("ERROR: Could not read from input file ", $config->{input}, "\n");
  }
}

# no file specified - try to read data off command line
else {
  $in_file_handle = 'STDIN';
  debug("Reading input from STDIN (or maybe you forgot to specify an input file?)...") unless defined $config->{quiet};
}

my @lines;

while(<$in_file_handle>) {
  chomp;
  
  next if $_ =~ /^#/; #skip lines starting with comments
  
  my @split = split /\t/, $_;
  
  my $data;
  
  # parse split data into hash
  for my $i(0..$#split) {
    $data->{$fields[$i]} = $split[$i];
  }
  
  # check chr name exists
  $data->{seqname} =~ s/chr//ig if !$config->{fasta_db}->length($data->{seqname});

  # check chr synonyms
  unless($config->{fasta_db}->length($data->{seqname})) {
    my $synonyms = get_seq_region_synonyms($config);
    $data->{seqname} = $synonyms->{$data->{seqname}} if $synonyms->{$data->{seqname}};
  }

  unless($config->{fasta_db}->length($data->{seqname})) {
    warn("WARNING: Could not find chromosome named ".$data->{seqname}." in FASTA file\n") unless $config->{missing_chromosomes}->{$data->{seqname}} || $config->{verbose};
    $config->{missing_chromosomes}->{$data->{seqname}} = 1;
    next;
  }

  push @lines, $data;
}

# find min, max
my ($min, $max) = (1e12, 0);
my $chr;

foreach my $line(@lines) {
  $min = $line->{start} if $line->{start} < $min;
  $max = $line->{end}   if $line->{end} > $max;

  die("ERROR: more than one seqname found") if $chr && $chr ne $line->{seqname};
  $chr = $line->{seqname};
}

# create FASTA
open FA, ">".$config->{output}.".fa";
print FA ">".$config->{output}."\n";
print FA $config->{fasta_db}->seq($chr, $min, $max);
close FA;

# create modified GFF
open GFF, ">".$config->{output}.".gff";

foreach my $line(@lines) {
  $line->{$_} -= ($min - 1) for qw(start end);
  $line->{seqname} = $config->{output};

  print GFF join("\t", map {$line->{$_}} @fields)."\n";
}

close GFF;

sub get_seq_region_synonyms {
  my $config = shift;

  if(!exists($config->{seq_region_synonyms})) {
    my $reg = 'Bio::EnsEMBL::Registry';

    $reg->load_registry_from_db(
      -host       => $config->{host},
      -user       => $config->{user},
      -pass       => $config->{password},
      -port       => $config->{port},
      -db_version => $config->{db_version},
      -species    => $config->{species} =~ /^[a-z]+\_[a-z]+/i ? $config->{species} : undef,
    );

    my $sa = $reg->get_adaptor($config->{species}, 'core', 'slice');

    my %synonyms = ();
    
    if($sa) {
      my $slices = $sa->fetch_all('toplevel');

      foreach my $slice(@$slices) {
        my $slice_name = $slice->seq_region_name;
        $synonyms{$_->name} = $slice_name for @{$slice->get_all_synonyms};
      }
    }

    $config->{seq_region_synonyms} = \%synonyms;
  }

  return $config->{seq_region_synonyms};
}


# DEBUG AND STATUS METHODS
##########################

# gets time
sub get_time() {
    my @time = localtime(time());

    # increment the month (Jan = 0)
    $time[4]++;

    # add leading zeroes as required
    for my $i(0..4) {
        $time[$i] = "0".$time[$i] if $time[$i] < 10;
    }

    # put the components together in a string
    my $time =
        ($time[5] + 1900)."-".
        $time[4]."-".
        $time[3]." ".
        $time[2].":".
        $time[1].":".
        $time[0];

    return $time;
}

# prints debug output with time
sub debug {
    my $text = (@_ ? (join "", @_) : "No message");
    my $time = get_time;
    
    print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
}

