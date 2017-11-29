#!/usr/local/bin/perl
use strict;
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

# get adaptor
my $sa = $reg->get_adaptor($species,"core","slice");

print $sa->fetch_by_region("chromosome", shift, shift, shift)->seq, "\n";