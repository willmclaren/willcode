#!/usr/bin/env perl

use Getopt::Long;
use Sereal::Encoder;
use Sereal::Decoder;
use MIME::Base64;
use Set::IntervalTree;
use DBI;
use Dave;

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Variation::Utils::VEP qw(parse_line);

my $config = {

  # database
  host => 'ens-livemirror',
  port => 3306,
  user => 'ensro',
  pass => undef,
  species => 'homo_sapiens',
  no_slice_cache => 1,

  # sqlite
  cache => $ENV{HOME}.'/.vep/vep.db',
  cache_types => [qw(gene)],

  # config
  object_cache_size => 5000,
};


GetOptions(
  $config,
  'cache|c=s',
  'build',
);

if($config->{build}) {
  build($config);
}

else {
  my $count = 0;

  while(<>) {
    next if /^\#/;
    my $line = $_;

    foreach my $vf(@{&parse_line($config, $line)}) {

      my $tree = interval_tree($config, $vf->{chr});

      foreach my $tr(
        map {@{$_->{transcripts}}}
        map {fetch_from_cache($config, 'gene', $_)}
        @{$tree->fetch($vf->{start}-5000, $vf->{end}+5000)}
      ) {
        my $tv = Bio::EnsEMBL::Variation::TranscriptVariation->new(
          -transcript        => $tr,
          -variation_feature => $vf,
          # -adaptor           => $config->{tva},
          -no_ref_check      => 1,
          -no_transfer       => 1
        );
        
        # prefetching stuff here prevents doing loads at the
        # end and makes progress reporting more useful
        # $tv->_prefetch_for_vep;

        $DB::single = 1;
        
        $vf->add_TranscriptVariation($tv);
      }

      $count += scalar @trs;
    }
  }

  print "Fetched $count trs\n";
}


sub build {
  my $config = shift;

  my $reg = 'Bio::EnsEMBL::Registry';
  $reg->load_registry_from_db(
    -host       => $config->{host},
    -user       => $config->{user},
    -pass       => $config->{password},
    -port       => $config->{port},
    -db_version => $config->{db_version},
    -species    => $config->{species} =~ /^[a-z]+\_[a-z]+/i ? $config->{species} : undef,
    -verbose    => $config->{verbose},
    -no_cache   => $config->{no_slice_cache},
  );

  Bio::EnsEMBL::Utils::Exception::verbose(1999) if defined($config->{no_slice_cache});

  my $sa = $reg->get_adaptor($config->{species}, 'core', 'slice');

  foreach my $chr(qw(21)) {
    my $slice = $sa->fetch_by_region('chromosome', $chr);#, 7000001, 8000000);
    my $sr_slice = $slice->seq_region_Slice();

    my @coords;

    foreach my $gene(map {$_->transfer($sr_slice)} @{$slice->get_all_Genes(undef, undef, 1)}) {
      my @trs;

      my $cs = $sr_slice->{coord_system};
      my $sa = $sr_slice->{adaptor};

      foreach my $tr(@{$gene->get_all_Transcripts}) {
        $tr->{_gene} = $gene;
        $tr->prefetch_vep_data();

        $DB::single = 1 if $tr->biotype eq 'protein_coding';

        push @trs, $tr;
      }

      $_->clean() for @trs;
      $gene->clean();

      $gene->{transcripts} = \@trs;

      my $id = add_to_cache($config, 'gene', $gene);

      push @coords, [$id, $gene->{start}, $gene->{end}];

      $sr_slice->{coord_system} = $cs;
      $sr_slice->{adaptor} = $sa;
    }

    store_tree($config, $chr, \@coords);
  }
}

sub serialize_and_encode {
  my $config = shift;
  my $obj = shift;

  my $encoder = encoder($config);

  return encode_base64($encoder->encode($obj));
}

sub deserialize_and_decode {
  my $config = shift;
  my $obj = shift;

  my $decoder = decoder($config);

  return $decoder->decode(decode_base64($obj));
}

sub encoder {
  my $config = shift;
  
  if(!exists($config->{_encoder})) {
    $config->{_encoder} = Sereal::Encoder->new({compress => 1});
  }

  return $config->{_encoder};
}

sub decoder {
  my $config = shift;

  if(!exists($config->{_decoder})) {
    $config->{_decoder} = Sereal::Decoder->new();
  }

  return $config->{_decoder}; 
}

sub add_to_cache {
  my $config = shift;
  my ($type, $obj) = @_;

  my $cache_db = cache_db($config);

  my $encoded = serialize_and_encode($config, $obj);

  $cache_db->do(qq{
    INSERT INTO $type (obj)
    VALUES ('$encoded')
  });

  return $cache_db->func('last_insert_rowid');
}

sub fetch_from_cache {
  my $config = shift;
  my ($type, $id, $no_cache) = @_;

  if(
    $no_cache or
    !exists($config->{_cached_objects}) or
    !exists($config->{_cached_objects}->{$type}) or
    !exists($config->{_cached_objects}->{$type}->{$id})
  ) {
    my $sth = fetch_sth($config, $type);
    $sth->execute($id);

    my $obj;
    $sth->bind_columns(\$obj);
    $sth->fetch();

    my $decoded = deserialize_and_decode($config, $obj);
    return $decoded if $no_cache;

    $config->{_cached_objects}->{$type}->{$id} = $decoded;

    push @{$config->{_cached_ids}->{$type}}, $id;

    if(scalar @{$config->{_cached_ids}->{$type}} > $config->{object_cache_size}) {
      my $delete = shift @{$config->{_cached_ids}->{$type}};
      delete $config->{_cached_objects}->{$type}->{$id};
    }
  }

  return $config->{_cached_objects}->{$type}->{$id};
}

sub fetch_sth {
  my $config = shift;
  my $type = shift;

  if(!exists($config->{_fetch_sth}) or !exists($config->{_fetch_sth}->{$type})) {
    my $cache_db = cache_db($config);

    $config->{_fetch_sth}->{$type} = $cache_db->prepare(qq{
      SELECT obj
      FROM $type
      WHERE id = ?
    });
  }

  return $config->{_fetch_sth}->{$type};
}

sub cache_db {
  my $config = shift;

  if(!exists($config->{_cache_db})) {
    $config->{_cache_db} = DBI->connect("dbi:SQLite:dbname=".$config->{cache},"","");

    # initialize tables
    foreach my $type(@{$config->{cache_types}}) {
      $config->{_cache_db}->do(qq{
        CREATE TABLE $type (
          id INTEGER PRIMARY KEY ASC,
          obj TEXT
        )
      }) unless $config->{_cache_db}->tables(undef, 'main', $type);
    }
  }

  return $config->{_cache_db};
}

sub store_tree {
  my $config = shift;
  my ($chr, $coords) = @_;

  my $cache_db = cache_db($config);

  $cache_db->do(qq{
    CREATE TABLE tree (
      id TEXT KEY,
      obj TEXT
    )
  }) unless $cache_db->tables(undef, 'main', 'tree');

  my $encoded = serialize_and_encode($config, $coords);

  $DB::single = 1;

  $cache_db->do(qq{
    INSERT INTO tree (id, obj)
    VALUES ('$chr', '$encoded')
  });

  return $cache_db->func('last_insert_rowid');
}

sub interval_tree {
  my $config = shift;
  my $chr = shift;

  if(!exists($config->{_interval_tree}) || !exists($config->{_interval_tree}->{$chr})) {
    my $tree = Set::IntervalTree->new();
    my $coords = fetch_from_cache($config, 'tree', $chr, 1);

    $tree->insert(@{$_}) for @$coords;

    $config->{_interval_tree}->{$chr} = $tree;
  }

  return $config->{_interval_tree}->{$chr};
}
