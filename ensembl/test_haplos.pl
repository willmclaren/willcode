#!/usr/bin/env perl

## YOU WILL NEED
## 1: a VCF file with phased genotypes for at least 1 individual
## 2: the ID of a transcript you're interested in

use strict;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Utils::Sequence qw(reverse_comp);

my $reg = 'Bio::EnsEMBL::Registry';
$reg->load_registry_from_db(
  -host => 'ensembldb.ensembl.org',
  -user => 'anonymous',
);

my $ta = $reg->get_adaptor('human', 'core', 'transcript');
my $t = $ta->fetch_by_stable_id('ENST00000390243');#'ENST00000390560');

my $vcf = shift;

my $tha = $reg->get_adaptor('human', 'variation', 'transcripthaplotype');

$tha->db->vcf_config({
  collections => [{
    id => 'user',
    species => 'homo_sapiens',
    assembly => 'GRCh38',
    type => 'local',
    filename_template => $vcf,
  }],
});

$tha->db->use_vcf(1);

# get VCF collection
my $vca = $reg->get_adaptor('human', 'variation', 'vcfcollection');
my $vc = $vca->fetch_all->[0];
# $vc->use_db(0);

my $thc = $tha->get_TranscriptHaplotypeContainer_by_Transcript($t);
my $s = $thc->get_all_Samples->[0];

foreach my $h(
  # grep {$_->name !~ /REF$/}
  @{$thc->get_all_CDSHaplotypes_by_Sample($s)}
) {
  my $seq = $h->seq();
  # reverse_comp(\$seq);
  $seq =~ s/(.{60})/$1\n/g;
  print ">2\n".$seq.($seq =~ /\n$/ ? '' : "\n");
}

use JSON;
my $json = JSON->new;
print $json->allow_blessed->convert_blessed->pretty->encode($thc);

1;
