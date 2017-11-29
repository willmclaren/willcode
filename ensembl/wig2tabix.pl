my (@d, $s, $c);

while(<>) {
  if(/^fixed.+chrom=(\w+).+start\=(\d+)/) {
    if(@d) {
      print "$c\t$s\t".($s + (scalar @d - 1))."\t".join(',', @d)."\n";
    }

    $c = $1;
    $s = $2;
    @d = ();
  }
  else {
    chomp;
    push @d, $_;
  }
}

print "$c\t$s\t".($s + (scalar @d - 1))."\t".join(',', @d)."\n";