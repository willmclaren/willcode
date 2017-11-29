#!/usr/bin/perl

%length = (
	1 => "247249719",
	2 => "242951149",
	3 => "199501827",
	4 => "191273063",
	5 => "180857866",
	6 => "170899992",
	7 => "158821424",
	8 => "146274826",
	9 => "140273252",
	10 => "135374737",
	11 => "134452384",
	12 => "132349534",
	13 => "114142980",
	14 => "106368585",
	15 => "100338915",
	16 => "88827254",
	17 => "78774742",
	18 => "76117153",
	19 => "63811651",
	20 => "62435964",
	21 => "46944323",
	22 => "49691432",
	'X' => "154913754",
	'Y' => "57772954"
);

$size = 30000000;

foreach $chr(1..22) {
	if($chr == 6) {
		$a = 65443059;
		$b = 94743101;
		
		$diff = $b - $a;
		
		$sfrom = sprintf("%.0f", ($a - ($size - $diff)/2));
		$sto = sprintf("%.0f", ($b + ($size - $diff)/2));
		
		$from = $sfrom;
		
		while($from > 1) {
			$to = $from;
			$from = $to - $size;
			
			$from = ($from < 1 ? 1 : $from);
			
			print "$chr\t$from\t$to\n";
		}
		
		print "$chr\t$sfrom\t$sto\n";
		
		$to = $sto;
		
		while($to < $length{$chr}) {
			$from = $to;
			$to = $from + $size;
			
			$to = ($to > $length{$chr} ? $length{$chr} : $to);
			
			print "$chr\t$from\t$to\n";
		}
	}
	
	else {
		$to = 0;
		
		while($to < $length{$chr}) {
			$from = $to;
			$to = $from + $size;
			
			$to = ($to > $length{$chr} ? $length{$chr} : $to);
			
			print "$chr\t$from\t$to\n";
		}
	}
}