#!/usr/bin/perl
use Math::Trig;

my $mode=1;
if(scalar(@ARGV)!=2){
	if(scalar(@ARGV)==3){
		if($ARGV[2]=='p'){
			$mode=2;
		}else{
			$mode=0;
		}
	}else{
		$mode=0;
	}
}

if($mode>0){
	my $outList=$ARGV[0];
	my $outputname=$ARGV[1];
	my %metaBinG2Out;
	open(OUTLIST,$outList)||die("can not open the file!\n");
	my @names=<OUTLIST>;chomp @names;
	close(OUTLIST);

	my $n=scalar(@names);
	my $i=0;
	foreach(@names){
		if(!$i){
			open(NAME,$_)||die("can not open ".$_."\n");
			while(my $line=<NAME>){
				chomp $line;
				if($line=~/species\*(.*)\*([0-9]+)\*(.*)/){
					$metaBinG2Out{$1}=$2."\_".$3;
				}
			}
			close(NAME);
		}else{
			open(NAME,$_)||die("can not open ".$_."\n");
			while(my $line=<NAME>){
				chomp $line;
				if($line=~/species\*(.*)\*([0-9]+)\*(.*)/){
					if($metaBinG2Out{$1}){
						$metaBinG2Out{$1}=$metaBinG2Out{$1}."\t".$2."\_".$3;
					}else{
						$metaBinG2Out{$1}="0\_0";
						for(my $j=1;$j<$i;$j++){
							$metaBinG2Out{$1}=$metaBinG2Out{$1}."\t"."0\_0";
						}
						$metaBinG2Out{$1}=$metaBinG2Out{$1}."\t".$2."\_".$3;
					}
				}
			}
			close(NAME);
			foreach(keys(%metaBinG2Out)){
				my @T=split(/\t/,$metaBinG2Out{$_});
				my $m=scalar(@T);
				if($m<($i+1)){
					$metaBinG2Out{$_}=$metaBinG2Out{$_}."\t0\_0";
				}
			}
		}
		$i++;
	}

	open(OUT,">$outputname")||die("can not open $outputname!\n");
	my $header="sample";
	foreach(@names){
		$header.="\t".$_;
	}
	print OUT $header."\n";
	my @keysOrdered=sort(keys(%metaBinG2Out));
	foreach(@keysOrdered){
		print OUT $_."\t".$metaBinG2Out{$_}."\n";
	}
	close(OUT);

	if($mode==2){
		open(JS,"ref/ref.js")||die("can not open ref.js");
		my @ref_js=<JS>; 
		close(JS);
		my $ref_js_content;
		foreach(@ref_js){
			$ref_js_content=$ref_js_content.$_;
		}
		my $content="var s=\"$header=M=";
		foreach(@keysOrdered){
			$content=$content.$_."\t".$metaBinG2Out{$_}."=M=";
		}
		$content=substr($content,0,length($content)-4);
		$content=$content."\";\n".$ref_js_content."\n";
		open(controller,">controller.js")||die("can not open controller.js!\n");
		print controller $content;
		close(controller);
		system("mkdir visualization");
		system("cp -r ref visualization");
		system("mv controller.js visualization");
		system("cp index.html visualization");
		system("tar -czvf visualization.tar.gz visualization");
		system("rm -rf visualization");
	}

}else{
	print "Usage:\n ./stats.all.pl [statsList] [outfile] [p](optional)\n";
}


