use strict;
use Time::HiRes qw(gettimeofday tv_interval);

use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor;

my $reg = 'Bio::EnsEMBL::Registry';
if($ARGV[0] && $ARGV[0] =~ /registry/) {
  $reg->load_all(shift @ARGV);
}
else {
  $reg->load_registry_from_db(-host => 'ensembldb.ensembl.org', -user => "anonymous", -port => 3337, -db_version => 78);
}

$Bio::EnsEMBL::Variation::DBSQL::VCFCollectionAdaptor::CONFIG_FILE = shift @ARGV;

my $vca = $reg->get_adaptor('human', 'variation', 'vcfcollection');
my $va  = $reg->get_adaptor('human', 'variation', 'variation');

my $c = $vca->fetch_all->[0];

my $v = $va->fetch_by_name('rs17149149');
my $vf = $v->get_all_VariationFeatures->[1];

my $gts = $c->get_all_IndividualGenotypeFeatures_by_VariationFeature($vf);

print STDERR "GOT ".(scalar @$gts)." GTs\n";

1;
