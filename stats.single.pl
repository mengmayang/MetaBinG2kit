#!/usr/bin/perl
use Math::Trig;

if(scalar(@ARGV)==2){
	my $classify=$ARGV[0];
	my $outputname=$ARGV[1];
	
	my %phylum;	
	my %class;
	my %order;
	my %family;
	my %genus;
	my %species0;
	my %species;

	my @phylum;	
	my @class;
	my @order;
	my @family;
	my @genus;
	
	my $readNum=0;
	my $cutoff=0.001;

	my @links;
	open(CLASSIFY,$classify)||die("can not open the file!\n");
	while(my $line=<CLASSIFY>){
		chomp $line;
		$readNum++;
		my @T=split(/\t/,$line);

		my $spe=$T[1]."_".$T[2]."_".$T[3]."_".$T[4]."_".$T[5]."_".$T[6];

		if(exists($species0{$spe})){
			$species0{$spe}++;
		}else{
			$species0{$spe}=1;
		}

	}
	close(CLASSIFY);



	my $cutNum=$readNum*$cutoff;
	#print $cutNum."\n";

	foreach my $k (keys %species0){
			$species{$k}=$species0{$k};
	}
	

	my @keys=sort(keys %species);


	my %species_new;
	foreach(@keys) {
		my @T=split(/\_/,$_);
		if($species{$_}<$cutNum){
			$name=$T[0]."\_".$T[1]."\_".$T[2]."\_".$T[3]."\_".$T[4]."\_"."other-genus-".$T[4];
			if(exists($species_new{$name})){
				$species_new{$name}+=$species{$_};
			}else{
				$species_new{$name}=$species{$_};
			}
		}else{
			$name=$T[0]."\_".$T[1]."\_".$T[2]."\_".$T[3]."\_".$T[4]."\_".$T[5];
			$species_new{$name}=$species{$_};
		}
	}
	my %genus_new;
	foreach(keys(%species_new)){
		my @T=split(/\_/,$_);
		if($species_new{$_}<$cutNum){
			$name=$T[0]."\_".$T[1]."\_".$T[2]."\_".$T[3]."\_"."other-family-".$T[3]."\_"."other-family-".$T[3];
			if(exists($genus_new{$name})){
				$genus_new{$name}+=$species_new{$_};
			}else{
				$genus_new{$name}=$species_new{$_};
			}
		}else{
			$name=$_;
			$genus_new{$name}=$species_new{$_};
		}
	}

	my %family_new;
	foreach(keys(%genus_new)){
		my @T=split(/\_/,$_);
		if($genus_new{$_}<$cutNum){
			$name=$T[0]."\_".$T[1]."\_".$T[2]."\_"."other-order-".$T[2]."\_"."other-order-".$T[2]."\_"."other-order-".$T[2];
			if(exists($family_new{$name})){
				$family_new{$name}+=$genus_new{$_};
			}else{
				$family_new{$name}=$genus_new{$_};
			}
		}else{
			$name=$_;
			$family_new{$name}=$genus_new{$_};
		}
	}

	my %order_new;
	foreach(keys(%family_new)){
		my @T=split(/\_/,$_);
		if($family_new{$_}<$cutNum){
			$name=$T[0]."\_".$T[1]."\_"."other-class-".$T[1]."\_"."other-class-".$T[1]."\_"."other-class-".$T[1]."\_"."other-class-".$T[1];
			if(exists($order_new{$name})){
				$order_new{$name}+=$family_new{$_};
			}else{
				$order_new{$name}=$family_new{$_};
			}
		}else{
			$name=$_;
			$order_new{$name}=$family_new{$_};
		}
	}

	my %class_new;
	foreach(keys(%order_new)){
		my @T=split(/\_/,$_);
		if($order_new{$_}<$cutNum){
			$name=$T[0]."\_"."other-phylum-".$T[0]."\_"."other-phylum-".$T[0]."\_"."other-phylum-".$T[0]."\_"."other-phylum-".$T[0]."\_"."other-phylum-".$T[0];
			if(exists($class_new{$name})){
				$class_new{$name}+=$order_new{$_};
			}else{
				$class_new{$name}=$order_new{$_};
			}
		}else{
			$name=$_;
			$class_new{$name}=$order_new{$_};
		}
	}

	my %phylum_new;
	foreach(keys(%class_new)){
		my @T=split(/\_/,$_);
		if($class_new{$_}<$cutNum){
			$name="other"."\_"."other-phylum-other"."\_"."other-phylum-other"."\_"."other-phylum-other"."\_"."other-phylum-other"."\_"."other-phylum-other";
			if(exists($phylum_new{$name})){
				$phylum_new{$name}+=$class_new{$_};
			}else{
				$phylum_new{$name}=$class_new{$_};
			}
		}else{
			$name=$_;
			$phylum_new{$name}=$class_new{$_};
		}
	}


	foreach(keys(%phylum_new)){
		my @T=split(/\_/,$_);
		if($phylum{$T[0]}){
			$phylum{$T[0]}=$phylum{$T[0]}+$phylum_new{$_};
		}else{
			$phylum{$T[0]}=$phylum_new{$_};
			@phylum=(@phylum,$T[0]);
		}
		my $classKey=$T[0]."_".$T[1];

		if($class{$classKey}){
			$class{$classKey}=$class{$classKey}+$phylum_new{$_};
		}else{
			$class{$classKey}=$phylum_new{$_};
			@class=(@class,$classKey);
		}
		my $orderKey=$T[0]."_".$T[1]."_".$T[2];

		if($order{$orderKey}){
			$order{$orderKey}=$order{$orderKey}+$phylum_new{$_};
		}else{
			$order{$orderKey}=$phylum_new{$_};	
			@order=(@order,$orderKey);
		}

		my $familyKey=$T[0]."_".$T[1]."_".$T[2]."_".$T[3];

		if($family{$familyKey}){
			$family{$familyKey}=$family{$familyKey}+$phylum_new{$_};
		}else{
			$family{$familyKey}=$phylum_new{$_};
			@family=(@family,$familyKey);
		}
		my $genusKey=$T[0]."_".$T[1]."_".$T[2]."_".$T[3]."_".$T[4];

		if($genus{$genusKey}){
			$genus{$genusKey}=$genus{$genusKey}+$phylum_new{$_};
		}else{
			$genus{$genusKey}=$phylum_new{$_};
			@genus=(@genus,$genusKey);
		}
	}


#写门的statistic结果

	my $file=$outputname;
	open(FILE,">$file")||die("ERROR!\n");
	close(FILE);
	open(FILE,">>$file")||die("ERROR!\n");
	
	my $percentCalSpe=0;
=pod
	my $percentCalGen=0;
	my $percentCalFam=0;
	my $percentCalOrd=0;
	my $percentCalCla=0;
	my $percentCalPhy=0;
=cut	
	my $level;
	my $s;

=pod
	@phylum=sort(@phylum);
	@class=sort(@class);
	@order=sort(@order);
	@family=sort(@family);
	@genus=sort(@genus);
=cut
	@species_name=keys(%phylum_new);
	@species_name=sort(@species_name);

=pod
	foreach(@phylum){
		my $percentage=$phylum{$_}/$readNum;
		$percentCalPhy=$percentCalPhy+$percentage;
		$level=1;
		my $color=getColor($percentCalPhy,$level);
		my @T=split(/\_/,$_);
		#my $name=$T[0];
		my $name=$T[0].";;;;;";
		my $line="phylum*".$name."*".$phylum{$_}."*".$percentage."*".$color."\n";
		print FILE $line;
	}

    foreach(@class){
        my $percentage=$class{$_}/$readNum;
		$percentCalCla=$percentCalCla+$percentage;
		$level=2;
		my $color=getColor($percentCalCla,$level);
		my @T=split(/\_/,$_);
		#my $name=$T[1];
		my $name=$T[0].";".$T[1].";;;;";
        my $line="class*".$name."*".$class{$_}."*".$percentage."*".$color."\n";
        print FILE $line;
    }

    foreach(@order){
        my $percentage=$order{$_}/$readNum;
		$percentCalOrd=$percentCalOrd+$percentage;
		$level=3;
		my $color=getColor($percentCalOrd,$level);
		my @T=split(/\_/,$_);
		#my $name=$T[2];
		my $name=$T[0].";".$T[1].";".$T[2].";;;";
        my $line="order*".$name."*".$order{$_}."*".$percentage."*".$color."\n";
        print FILE $line;
    }
	
	foreach(@family){
        my $percentage=$family{$_}/$readNum;
		$percentCalFam=$percentCalFam+$percentage;
		$level=4;
		my $color=getColor($percentCalFam,$level);
		my @T=split(/\_/,$_);
		#my $name=$T[3];
		my $name=$T[0].";".$T[1].";".$T[2].";".$T[3].";;";
        my $line="family*".$name."*".$family{$_}."*".$percentage."*".$color."\n";
        print FILE $line;
    }
 

    foreach(@genus){
        my $percentage=$genus{$_}/$readNum;
		$percentCalGen=$percentCalGen+$percentage;
		$level=5;
		my $color=getColor($percentCalGen,$level);
		my @T=split(/\_/,$_);
		#my $name=$T[4];
		my $name=$T[0].";".$T[1].";".$T[2].";".$T[3].";".$T[4].";";
        my $line="genus*".$name."*".$genus{$_}."*".$percentage."*".$color."\n";
        print FILE $line;
    }
=cut

    foreach(@species_name){
         my $percentage=$phylum_new{$_}/$readNum;
		 #$percentCalSpe=$percentCalSpe+$percentage;
		 $level=6;
		 #my $color=getColor($percentCalSpe,$level);
         my @T=split(/\_/,$_);
         #my $name=$T[5];
         my $name=$T[0].";".$T[1].";".$T[2].";".$T[3].";".$T[4].";".$T[5];
         #my $line="species*".$name."*".$phylum_new{$_}."*".$percentage."*".$color."\n";
		 my $line="species*".$name."*".$phylum_new{$_}."*".$percentage."\n";
         #my $line=$_.":".$species{$_}.":".$percentage."\n";
         print FILE $line;
    }
    
	close(FILE);

}else{
	print "Usage:\n perl stats.pl classify outputname\n";
}

sub	getColor{
	my $percentCal=$_[0];
	my $level=$_[1];
	my $h=2*pi*$percentCal;
	my $s=max(0.2,1-$level*0.12);
	my $v=1;
	my $color=getHSVColor($h,$s,$v);
	return $color;
}

sub getHSVColor {
	my @hsv=@_;
	my $h=$hsv[0];
	my $s=$hsv[1];
	my $v=$hsv[2];
	my $r;
	my $g;
	my $b;
	my $i;
	my $f;
	my $p;
	my $q;
	my $t;

	$i = int($h * 6);
	$f = $h * 6 - $i;
	$p = $v * (1 - $s);
	$q = $v * (1 - $f * $s);
	$t = $v * (1 - (1 - $f) * $s);
	
	switch :{
		$i%6==0 && do{$r = $v; $g = $t; $b = $p; last;};
		$i%6==1 && do{$r = $q; $g = $v; $b = $p; last;};
		$i%6==2 && do{$r = $p; $g = $v; $b = $t; last;};
		$i%6==3 && do{$r = $p; $g = $q; $b = $v; last;};
		$i%6==4 && do{$r = $t; $g = $p; $b = $v; last;};
		$i%6==5 && do{$r = $v; $g = $p; $b = $q; last;};	
	}

	my $rgb='#'.toHex($r*255).toHex($g*255).toHex($b*255);
	return $rgb;
}

sub toHex(num){
	my $num= $_[0];
	my $num=int($num);
	my $num16=sprintf("%x",$num);
	return $num16;
}

sub max{
	my $mx = $_[0];
	for my $e(@_) {$mx = $e if ($e > $mx);}
	return $mx;
}
