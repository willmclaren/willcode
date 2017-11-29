#!/software/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

use Getopt::Long;
use Digest::MD5 qw(md5_hex);

my ($host, $port, $user, $pass, $species, $version, $registry, $tr_id, $analysis);

GetOptions(
	'host=s'   => \$host,
	'user=s'   => \$user,
	'pass=s'   => \$pass,
	'port=i'   => \$port,
  'species=s' => \$species,
  'version=i' => \$version,
  'registry=s' => \$registry,
  'transcript|t=s' => \$tr_id,
  'analysis|a=s' => \$analysis,
);

$analysis ||= 'sift';
die("ERROR: No transcript given with --transcript/-t\n") unless defined($tr_id);


my $reg = 'Bio::EnsEMBL::Registry';

$host ||= 'ensembldb.ensembl.org';
$port ||= 5306;
$user ||= 'anonymous';
$pass ||= '';
$species ||= 'homo_sapiens';


if(defined($registry)) {
  $reg->load_all($registry);
}
else {
  $reg->load_registry_from_db(
    -host       => $host,
    -user       => $user,
    -pass       => $pass,
    -port       => $port,
    -db_version => $version,
  );
}

my $ta = $reg->get_adaptor($species, 'core', 'transcript');
my $t = $ta->fetch_by_stable_id($tr_id) or die("ERROR: Could not fetch transcript $tr_id\n");

die("ERROR: Transcript has no translation\n") unless $t->translation;
my $peptide = $t->translation->seq;

my $m = 'fetch_'.$analysis.'_predictions_by_translation_md5';

my $pfpma = $reg->get_adaptor($species, 'variation', 'proteinfunctionpredictionmatrix');
my $pfpm = $pfpma->$m(md5_hex($peptide));

my @aas = qw(A C D E F G H I K L M N P Q R S T V W Y);

print join("\t", ("#pos", @aas))."\n";

foreach my $pos(1..length($peptide)) {
  my @out = ($pos);

  foreach my $aa(@aas) {
    if(my @pred = $pfpm->prediction_from_matrix($pos, $aa)) {
      push @out, $pred[1] // "-";
    }
    else {
      push @out, "-";
    }
  }
  print join("\t", @out)."\n";
}


1;
