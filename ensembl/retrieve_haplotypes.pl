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

if(defined($host) && $host =~ /staging|variation|livemirror/) {
	$port ||= 3306;
	$user ||= 'ensro';
	$pass ||= '';
}

else {
	$host = 'ensembldb.ensembl.org';
	$port ||= 5306;
	$user ||= 'anonymous';
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

my $tha = $reg->get_adaptor($species,'variation','transcripthaplotype');
my $ths = $tha->fetch_all_by_transcript_stable_id('ENST00000502692');

$DB::single = 1;


1;
