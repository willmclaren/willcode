$db = shift; while(<>) { chomp; print `sqlite3 $db "select chr,start,end,alleles,strand from name_to_vep where name = '$_' ; "`;}
