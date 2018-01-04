#!/usr/bin/perl

$args{'d'} = "\t";

%args_with_vals = (
	'd' => 1,
);

#process arguments
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


# now get math arguments
$cola = shift @ARGV or die "First column not specified\n";
$opa = shift @ARGV or die "Operator not specified\n";
$colb = shift @ARGV or die "Second column not specified\n";

# determine what operation we are doing
if($opa =~ /plus|add/i) {
	$op = "plus";
}

elsif($opa =~ /min|sub/i) {
	$op = "minus";
}

elsif($opa =~ /div|ov/i) {
	$op = "div";
}

elsif($opa =~ /by|mul|tim/i) {
	$op = "by";
}

else {
	die "Operation $opa not recognised\n";
}

$cola--;
$colb--;

$line = 1;

while(<>) {
	chomp;
	
	@data = split /$args{'d'}/, $_;
	
	die "Column $cola specified out of range \(".(scalar @data)." columns on line $line\)\n" if $cola > $#data;
	die "Column $colb specified out of range \(".(scalar @data)." columns on line $line\)\n" if $colb > $#data;
	
	$a = $data[$cola];
	$b = $data[$colb];
	
	if($op eq "plus") {
		$res = $a + $b;
	}
	
	elsif($op eq "minus") {
		$res = $a - $b;
	}
	
	elsif($op eq "div") {
		$res = ($b == 0 ? "DIV0" : $a / $b);
	}
	
	elsif($op eq "by") {
		$res = $a * $b;
	}
	
	print "$_".$args{'d'}."$res\n";
}
	