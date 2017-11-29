#!/usr/bin/env perl

use Bio::DB::Fasta;
use Getopt::Long;
use Scalar::Util qw(looks_like_number);

my $config = {
  chunk_size => 10,
  deletions  => 1,
  insertions => 1,
  fasta      => undef,
  single     => 0,
  random     => undef,
};


GetOptions(
  $config,
  'chunk_size|c=i',
  'deletions|d=i',
  'insertions|i=i',
  'fasta|f=s',
  'regions|r=s',
  'single|s',
  'random|m=f'
);

my $fasta = $config->{fasta};
die("ERROR: No FASTA file given\n") unless $fasta;
die("ERROR: FASTA file does not exist\n") unless -e $fasta;

eval q{ use Bio::DB::HTS::Faidx; };

my ($fasta_db, $faidx);

if($@) {
  $fasta_db = Bio::DB::Fasta->new($fasta);
}
else {
  $fasta_db = Bio::DB::HTS::Faidx->new($fasta);
  $faidx = 1;
}

my $chunk_size = $config->{chunk_size};
die("ERROR: --chunk_size must be > 0\n") unless $chunk_size;

die("ERROR: --random must be 0 < r < 1\n")
  if $config->{random} &&
  (
    !looks_like_number($config->{random}) ||
    $config->{random} <= 0 ||
    $config->{random} >= 1
  );
our $RANDOM = $config->{random};

# bases
my @bases = qw(A C G T);

# now create possible seq inserts up to maximum size
# will always have reference base prefixed
my $suffixes_by_size = {
  1 => \@bases
};
for(my $i = 2; $i <= $config->{insertions}; $i++) {
  my @seqs;

  foreach my $ps(@{$suffixes_by_size->{$i - 1}}) {
    push @seqs, map {$ps.$_} @bases;
  }

  $suffixes_by_size->{$i} = \@seqs;
}

my @regions;

# user specified
if($config->{regions}) {
  while($config->{regions} =~ m/([^:]+):(\d+)\-(\d+)(\,|$)/g) {
    push @regions, {
      chr => $1,
      start => $2,
      end => $3,
    };
  }
}
else {
  push @regions, {
    chr => $_,
    start => 1,
    end => $fasta_db->length($_)
  } for ($faidx ? $fasta_db->get_all_sequence_ids() : $fasta_db->get_all_primary_ids());
}

print "##fileformat=VCFv4.1\n";
print '#'.join("\t", qw(CHROM POS ID REF ALT QUAL FILTER INFO))."\n";

foreach my $region(@regions) {

  my ($chr, $start, $chr_length) = ($region->{chr}, $region->{start}, $region->{end});

  my $actual_chr_end = $fasta_db->length($chr);
  $region->{end} = $actual_chr_end if $region->{end} > $actual_chr_end;

  while($start < $chr_length) {

    # random?
    if(!rand_ok($chunk_size)) {
      $start += $chunk_size;
      next;
    }

    my $end = ($start + $chunk_size) - 1;
    $end += $config->{deletions};

    my $chunk_seq = uc(
      $faidx ? 
      ($fasta_db->get_sequence($chr.':'.$start.'-'.$end))[0] :
      $fasta_db->seq($chr, $start => $end)
    );

    my $pos = 0;

    while($pos < $chunk_size) {
      my $ref_seq = substr($chunk_seq, $pos, 1);

      # add SNPs
      my @alts = grep {$_ ne $ref_seq} @bases;

      if($config->{single}) {
        for(@alts) {
          printf("%s\t%i\t.\t%s\t%s\t.\t.\t.\n", $chr, $pos + $start, $ref_seq, $_) if rand_ok();
        }
      }
      elsif(rand_ok()) {
        printf("%s\t%i\t.\t%s\t%s\t.\t.\t.\n", $chr, $pos + $start, $ref_seq, join(",", @alts));
      }

      # add insertions
      my $ins_size = 0;
      my @ins;
      while(++$ins_size <= $config->{insertions}) {
        push @ins, map {$ref_seq.$_} @{$suffixes_by_size->{$ins_size}};
      }

      if(scalar @ins) {
        if($config->{single}) {
          for(@ins) {
            printf("%s\t%i\t.\t%s\t%s\t.\t.\t.\n", $chr, $pos + $start, $ref_seq, $_) if rand_ok(0.01);
          }
        }
        elsif(rand_ok(0.01)) {
          printf("%s\t%i\t.\t%s\t%s\t.\t.\t.\n", $chr, $pos + $start, $ref_seq, join(",", @ins));
        }
      }

      # add deletions
      my $del_size = 0;
      while(++$del_size <= $config->{deletions}) {
        next unless rand_ok(0.01);
        my $del_seq = substr($chunk_seq, $pos, $del_size + 1);
        printf("%s\t%i\t.\t%s\t%s\t.\t.\t.\n", $chr, $pos + $start, $del_seq, $ref_seq);
      }

      $pos++;
    }

    $start += $chunk_size;

    # exit(0) if $start >= 100;
  }
}

sub rand_ok {
  return !$RANDOM || (rand() / ($_[0] // 1)) < $RANDOM;
}
