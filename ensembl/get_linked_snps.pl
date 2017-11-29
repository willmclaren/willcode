#!/software/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Registry;
use Getopt::Long;
use FileHandle;

my $reg = 'Bio::EnsEMBL::Registry';

my $config = {};

GetOptions(
	$config,
	'help',
	'registry=s',
	'host=s',
	'user=s',
	'port=s',
	'password=s',
	'species=s',
	'input=s',
	'population=s',
	'threshold=s',
);

&usage() if defined($config->{help});

# defaults
$config->{species}    ||= 'homo_sapiens';
$config->{population} ||= "1000GENOMES:pilot_1_CEU_low_coverage_panel";
$config->{threshold}  ||= 0.9;

if(defined($config->{registry})) {
	$reg->load_all($config->{registry});
}

else {
	$reg->load_registry_from_db(
		-host    => $config->{host} || 'ensembldb.ensembl.org',
		-user    => $config->{user} || 'anonymous',
		-pass    => $config->{password} || '',
		-port    => $config->{port} || 5306,
		-species => $config->{species},
	);
}

my $va = $reg->get_adaptor("human", "variation", "variation");
my $ldca = $reg->get_adaptor("human", "variation", "ldfeaturecontainer");
my $pa = $reg->get_adaptor("human", "variation", "population");

my $pop = $pa->fetch_by_name($config->{population});

my $in_file_handle = new FileHandle;
    
if(defined($config->{input})) {
	
	# check defined input file exists
	die("ERROR: Could not find input file ", $config->{input}, "\n") unless -e $config->{input};
	
	if($config->{input} =~ /\.gz$/){
		$in_file_handle->open($config->{compress}." ". $config->{input} . " | " ) or die("ERROR: Could not read from input file ", $config->{input}, "\n");
	}
	else {
		$in_file_handle->open( $config->{input} ) or die("ERROR: Could not read from input file ", $config->{input}, "\n");
	}
}

# no file specified - try to read data off command line
else {
	$in_file_handle = 'STDIN';
}

while(<$in_file_handle>) {
	chomp;
	
	my $v = $va->fetch_by_name($_);
	
	next unless defined $v;
	
	my $count = 0;
	
	foreach my $vf(@{$v->get_all_VariationFeatures}) {
		
		my $ldc = $ldca->fetch_by_VariationFeature($vf, $pop);
		
		foreach my $hash(grep {$_->{r2} >= $config->{threshold}} @{$ldc->get_all_r_square_values}) {
			my $vf2 = ($hash->{variation1}->dbID eq $vf->dbID ? $hash->{variation2} : $hash->{variation1});
			
			print join "\t", (
				$vf->variation_name,
				$vf->seq_region_name,
				$vf->seq_region_start,
				$vf2->variation_name,
				$vf2->seq_region_start,
				$hash->{r2}
			);
			print "\n";
			
			$count++;
		}
	}
	
	print $v->name, "\tNone\n" unless $count;
}

sub usage {
	my $usage =<<END;
perl get_linked_snps.pl -i variants.txt

--help            Show this message

-i | --input      Input file (STDIN if not specified)
--population      Population name
-t | --threshold  r^2 threshold (default=0.8)

--species         Species (default=human)

--registry        Registry file
--host            DB host
--port            DB port
--user            DB username
--password        DB password
END

	print $usage;
	exit(0);
}