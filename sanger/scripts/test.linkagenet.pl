#!/usr/bin/perl

use lib "/nfs/team71/psg/wm2/Perl/LinkageNet";
use LinkageNet;

%args_with_vals = (
	's' => 1,
);

# process arguments from command line
while($ARGV[0] =~ /^\-/) {
	$arg = shift @ARGV;
	$arg =~ s/^\-//g;
	
	$args{$arg} = ($args_with_vals{$arg} ? shift @ARGV : 1);
}


if($args{'s'}) {
	open IN, $args{'s'} or die "Could not open SNP info file $args{'s'}\n";
	
	debug("Loading SNP info from $args{'s'}");
	
	$line = 1;
	
	while(<IN>) {
		chomp;
		
		@data = split /\s+/, $_;
		
		# my-style map file
		if(scalar @data == 3) {
			($snp, $chr, $pos) = @data;
		}
		
		# PLINK-style map file
		elsif(scalar @data == 4) {
			($chr, $snp, $crap, $pos) = @data;
		}
		
		$bypos{$chr}{$pos} = $snp;
		
		$snps{$snp}{'chr'} = $chr;
		$snps{$snp}{'pos'} = $pos;
	}
	
	close IN;
}


while(<>) {
	chomp;
	
	($sample, $a, $b, $type) = split /\t/, $_;
	
	if(!$nets{$sample}) {
		$nets{$sample} = LinkageNet::Network::new;
	}
	
	$node_a = LinkageNet::Node::new($a, $snps{$a}{'chr'}, $snps{$a}{'pos'});
	$node_b = LinkageNet::Node::new($b, $snps{$b}{'chr'}, $snps{$b}{'pos'});
	
	$node_a->link($node_b->id, $type);
	$node_b->link($node_a->id, $type);
	
	#print "Linking ".$node_a->id." to ".$node_b->id." type $type\n";
	
	$nets{$sample}->addNode($node_a);
	$nets{$sample}->addNode($node_b);
	
	
	#$link = LinkageNet::Link::new($node_a, $node_b, $type);
	#$nets{$sample}->addLink($link);
}


foreach $sample(keys %nets) {
	print "> $sample\n";

	foreach $node($nets{$sample}->getAllNodes()) {
		foreach $b(keys %{$node->{'links'}}) {
			$type = $node->{'links'}->{$b};
			
			print $node->id." is linked to ".$b." by TYPE:$type\n";
		}
	}
}






# GET CURRENT DATE AND TIME IN SQL FORMAT
#########################################

sub getTime() {
	my @time = localtime(time());

	# increment the month (Jan = 0)
	$time[4]++;

	# add leading zeroes as required
	for my $i(0..4) {
		$time[$i] = "0".$time[$i] if $time[$i] < 10;
	}

	# put the components together in a string
	my $time =
# 		($time[5] + 1900)."-".
# 		$time[4]."-".
# 		$time[3]." ".
		$time[2].":".
		$time[1].":".
		$time[0];

	return $time;
}


# DEBUG SUBROUTINE
##################

sub debug {
	my $text = (@_ ? shift : "No message");
	my $time = getTime;
	my $pid = $$;
	
	print $time." - ".$text.($text =~ /\n$/ ? "" : "\n");
} 