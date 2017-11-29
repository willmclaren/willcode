#!/software/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;

use Getopt::Long;

my ($host, $port, $user, $pass, $species, $version, $registry);

GetOptions(
	'host=s'   => \$host,
	'user=s'   => \$user,
	'pass=s'   => \$pass,
	'port=i'   => \$port,
  'species=s' => \$species,
  'version=i' => \$version,
  'registry=s' => \$registry,
);


my $reg = 'Bio::EnsEMBL::Registry';

if(defined($host) && $host =~ /staging|variation|livemirror|genebuild|ensdb/) {
	$port ||= 3306;
	$user ||= 'ensro';
	$pass ||= '';
}

else {
	$host ||= 'mysql-ensembl-mirror.ebi.ac.uk';
	$port ||= 4240;
	$user ||= 'ensro';
	$pass ||= '';
}

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

$DB::single = 1;

my $va = $reg->get_adaptor($species,'variation','variation');
my $v = $va->fetch_by_name('rs699');

my $vf = shift @{$v->get_all_VariationFeatures};

$DB::single = 1;

my $sa = $reg->get_adaptor($species, 'core', 'slice');
my $s = $sa->fetch_by_region('chromosome', 1, 230845294, 230846294);

$DB::single = 1;

1;
