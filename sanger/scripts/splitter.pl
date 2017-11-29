#!/software/bin/perl

use warnings;
use strict;

use IO::File;

my $status = ($ARGV[0] =~ /OBC/) ? 'controls' : 'cases';
my ($chromosome) = $ARGV[0] =~ /_([^_.]+).txt$/;
#my $folder = "/lustre/work1/sanger/ew2/ANALYSIS_26.02.07/CHR$chromosome";
my $folder = "/tmp/CHR$chromosome";

if ( -d $folder ) {
    system("rm -rf $folder");
}

system("mkdir -p $folder");
				     
my $input = IO::File->new("cut -f1 $ARGV[0]|")
    or die "Could not open input file $ARGV[0] : $!\n";

my ($dbSNP, $wtccc, $allele, $freq);
my (@dbSNPs);

# Put the following in a block so the %dbSNPs gets freed when we're
# finished with it.

{
    my %dbSNPs;

    # Get list of samples and dbSNP entries
    while (<$input>) {
	chomp;
	$dbSNPs{$_} = undef;
    }

    $input->close;

    @dbSNPs = keys %dbSNPs;
}

my $total_snps = scalar(@dbSNPs);
my $filecount = int($total_snps / 500) + 1;

# Initialise some variables
my $oldwtccc = '';
my @outfile = ();
my $data = {};
local $, = " ";

# Open the output files
for (my $i = 0; $i<$filecount; $i++) {
    $outfile[$i] = &new_outfile($i);
}

# Spawn a process to sort the data file on its second column (WTCCC sample)
# and read the output

$input->open("sort -k2 $ARGV[0]|")
    or die "Could not open pipe to sort $ARGV[0] : $!\n";

while (<$input>) {
    my ($dbSNP, $wtccc, $allele, undef) = split(/\s+/);
    if ($oldwtccc && ($wtccc ne $oldwtccc)) {
	&print_data($oldwtccc);
	$data = {};
    }
    $oldwtccc = $wtccc;
    $data->{$dbSNP} = $allele;
}

# When we reach the end of the file, we need to print out whatever
# data we have left
&print_data($oldwtccc);

# Close all output files.
foreach (@outfile) {
    $_->close;
}

$input->close;

exit(0);

# END OF MAIN PROGRAM.  SUBROUTINES FOLLOW.

sub print_data {
    my ($sample) = @_;
    my ($start, $i, $end);
    for ($start = 0, $i = 0; $start < scalar(@dbSNPs); $i++, $start+=500) {
	$end = $start + 499;
	$end = $#dbSNPs if ($end > $#dbSNPs);
	$outfile[$i]->print($sample,
			    (map { $data->{$_} } @dbSNPs[$start .. $end]),
			    "\n");
    }
}

sub new_outfile {
    my ($fileno) = @_;
    my $outfile;

    my $filename = sprintf('%s_chr%s_%d.txt', $status, $chromosome, $fileno);

    $outfile = IO::File->new(">$folder/$filename") or
	die "Could not open $filename for writing: $!\n";

    $outfile->print('wtccc_id', @dbSNPs, "\n");

    return $outfile;
}
