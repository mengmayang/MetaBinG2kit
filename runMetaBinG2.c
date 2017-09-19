#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <getopt.h>
#include "io.h"

void showHelp(){
	char *usage="*******************************************************************\nMetaBinG2kit\n\nThis software is designed for sequence classification. The core program is MetaBinG2. MetaBinG2kit integrate MetaBinG2 and stats.single.pl.\n*******************************************************************\n\nUsage:\n\tMetaBinG2kit -i [sequence.fa] -o [classifyResult] -d [database] -t [threads]\n\nParameters:\n\n\t-i*\tSequence in fa format which stands for a sample.(required)\n\n\t-o*\tThe name of classified result.(required)\n\n\t-d*\tSelect database.(required)\n\n\t-t\tThreads number (default is 1,the max number is 8).\n\n\t-s\tScript to analyze the result of MetaBinG2's classification process.(default is stats.single.pl in current dir)\n\n\t-h\thelp.\n\nFor more support,please see:\n<http://cgm.sjtu.edu.cn>\n";
	printf("%s\n",usage);

}

struct globalArgs_t{
	char *fa;
	char *out;
	int thread;
	char *db;
	char *pl;
} globalArgs;

int main(int argc,char **argv){
	int required_para=0;
	if(argc>11 || argc<2){
		printf("%d\n",argc);
		showHelp();
	}else{
		globalArgs.thread=1;
		globalArgs.pl="./stats.single.pl";

		int ch;
		int isShow=1;

		while((ch=getopt(argc,argv,"i:d:t:o:s:h"))!=-1){
			switch(ch){
				case 'i':
					globalArgs.fa=optarg;
					required_para++;
					break;
				case 'o':
					globalArgs.out=optarg;
					required_para++;
					break;
				case 'd':
					globalArgs.db=optarg;		
					required_para++;
					break;
				case 't':
					globalArgs.thread=atoi(optarg);	
					break;
				case 's':
					globalArgs.pl=optarg;
					break;
				case 'h':
					showHelp();
					isShow=0;
					break;
				case '?':
					showHelp();
					isShow=0;
					break;	
				default:
					printf("other option :%c\n",ch);
			}
		}
		if(required_para<3 && isShow){
			printf("\n!!Attention: -i -o -d are required!\n\n");
			showHelp();
		}else{

			if(globalArgs.thread>8){
				printf("Parameters ERROR: The max thread number is 8.\n");	
			}else if(access(globalArgs.fa,0)){
				printf("Parameters ERROR: \"%s\" does not exist!\n",globalArgs.fa);
			}else if(access(globalArgs.db,0)){
				printf("Parameters ERROR: \"%s\" does not exist!\n",globalArgs.db);
			}else if(access(globalArgs.pl,0)){
				printf("Parameters ERROR: \"%s\" does not exist!\n",globalArgs.pl);
			}else{
				char cmd[1000];
				sprintf(cmd,"./MetaBinG2 \"%s\" \"%s\" \"%d\" \"%s\"",globalArgs.fa,globalArgs.db,globalArgs.thread,globalArgs.out);
				//printf("%s\n",cmd);
				char statsName[1000];
				sprintf(statsName,"%s.stats",globalArgs.out);
				
				char cmd1[1000];
				sprintf(cmd1,"perl %s %s %s",globalArgs.pl,globalArgs.out,statsName);
				//printf("%s\n",cmd1);
				system(cmd);
				system(cmd1);
				printf("Success!\n");
				
				
				
			}
			
		}
	}

}
