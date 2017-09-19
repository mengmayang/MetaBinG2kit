#!/usr/bin/perl
$id=$ARGV[1];
$species=$ARGV[2];
$genus=$ARGV[3];
$family=$ARGV[4];
$order=$ARGV[5];
$class=$ARGV[6];
$phylum=$ARGV[7];
$out=$ARGV[8];

$n=6;
my $col_num=4**$n;
my @kfreq=(0)x $col_num;
my @kmer_num_m=(0)x ($col_num/4);

$fa="";
$seq="";

my $fan=0;
if(scalar(@ARGV)==9){

	if(-e $ARGV[0]){
		#$/=">";
		
		if(-e "db"){
			open(dbfile,">>$out");			
		}else{
			open(dbfile,">db");
		}
		open(file,$ARGV[0]);
		#$fa=<file>;
        @fa_arr=<file>;chomp @fa_arr;
        $fan=scalar(@fa_arr);
        close(file);

        for($i=0;$i<$fan;$i++){
            if($fa_arr[$i]!~/>/){
				$seq=char2num($fa_arr[$i]);
				computep();
				$seq=revcompl($seq);
				computep();				
                #$seq.=$fa_arr[$i];
            }
        }
		my $vector=$id."\t".$species."\t".$genus."\t".$family."\t".$order."\t".$class."\t".$phylum;
		#print dbfile $id,"\t",$species,"\t",$genus,"\t",$family,"\t",$order,"\t",$class,"\t",$phylum;
		for($j=0;$j<$col_num;$j++){
			my $index=int($j/4);
			if($kmer_num_m[$index]>0 && $kfreq[$j]>0){
				$vector=$vector."\t".sprintf("%0.4f",(-1)*log($kfreq[$j]/$kmer_num_m[$index]));
				#print dbfile "\t",sprintf("%0.4f",(-1)*log($kfreq[$j]/$kmer_num_m[$index]));
			}else{
				$vector=$vector."\t"."10";
				#print dbfile "\t",10;
			}
		}
		$vector=$vector."\n";
		print dbfile $vector;
		close(dbfile);
	}else{
		print "ERROR! Cannot access $ARGV[0]: No such file or directory\n";
		usage();
	}
}else{
	usage();
}

sub usage(){
	print "USAGE: ./addref [FASTA file] [id] [species] [genus] [family] [order] [class] [phylum] [outname]","\n";
	exit;
}

sub computep{
		#%kfreq=();
		for($j=0;$j<length($seq)-$n+1;$j++){
			my $c=substr($seq,$j,$n);
			my $index=0;
            for(my $p=0;$p<length($c)-1;$p++){
                $index=$index*4+substr($c,$p,1);
            }
            $kmer_num_m[$index]++;
            $index=$index*4+substr($c,length($c)-1,1);
            $kfreq[$index]++;
		}
}
			
sub revcompl {
	my ($seqt)=@_;
        $seqt = reverse $seqt;
        #$seqt =~ tr/ACGTacgt/TGCAtgca/;
        $seqt =~ tr/0123/1032/;
    	return $seqt;
}


sub char2num{
    my $chars=$_[0];
    my $nums;
    for(my $i=0;$i<length($chars);$i++){
        my $c=substr($chars,$i,1);
        if($c eq 'A' || $c eq 'a'){
            $nums=$nums.'0';
        }elsif($c eq 'T' || $c eq 't'){
            $nums=$nums.'1';
        }elsif($c eq 'C' || $c eq 'c'){
            $nums=$nums.'2';
        }elsif($c eq 'G' || $c eq 'g'){
            $nums=$nums.'3';
        }
    }
        return $nums;
}
