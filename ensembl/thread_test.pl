use threads;
use threads::shared;

my %hash :shared = {
  name => 'dave'
};

my $obj :shared;

$obj = \%hash;

 my $thr1 = threads->create(
  sub {
    my $obj = shift;
    $obj->{fish} = 'colin';
    return $obj;
  },
  $obj
);

use Data::Dumper;
$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 1;
print STDERR Dumper $thr1->join();

use Data::Dumper;
$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Indent = 1;
print STDERR Dumper $obj;