/* Includes, system */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <math.h>
/* Includes, cuda */
#include "cublas.h"
#include <cuda_runtime.h>
#include <sys/timeb.h>
#include <pthread.h>

//global variable
int *statsNum;
char** tmp;
char** tmp1;

int threadNum;


int kmer=0;
int seqvlen;
int buff;
int mrow;
float alpha;

char **datas;
float* datad;
// float* d_datad;
float* sigmaG;
//float *d_sigmaG;
int flag;
int mcolmax;

long long getSystemTime(){
        struct timeb t;
        ftime(&t);
        return 1000*t.time+t.millitm;
}



void checkCUDAError(const char *msg)     
{     
    cudaError_t err = cudaGetLastError();     
    if( cudaSuccess != err)      
    {     
        fprintf(stderr, "Cuda error: %s: %s.\n", msg,      
        cudaGetErrorString( err) );     
        exit(EXIT_FAILURE);     
    }                              
}    
void classify(char** datas,float* scorelist,int buff,int mrow,char** titlel,float* sigma,int* statsNum,int flag,float alpha){
     for(int i=0;i<buff;i++){
         float s1=1e10;
         int r1=0;
         float stmp=0;

         for(int j=1;j<mrow;j++){
             stmp=scorelist[j*buff+i]*(1+alpha*sigma[j]);
             if(stmp<s1){
                 s1=stmp;r1=j*buff+i;
             }
         }

         statsNum[(r1-i)/buff]++;


         if(flag){
             printf("%s",titlel[i]);
             for(int j=6;j>=0;j--){
                 printf("\t%s",datas[7*(r1-i)/buff+j]);
             }
             printf("\n");
         }

     }
	
}
//cuda kernel
__global__ void parallel(float *d_scorelist,float *d_sigma,int *d_index,int buff,int mrow,float alpha){
        int i=threadIdx.x+blockIdx.x*blockDim.x;
        int j;
        float m=1e10;
        float tmp;
        if(i<buff){
				d_index[i]=0;
                for(j=0;j<mrow;j++){
                        tmp=d_scorelist[j*buff+i]*(1+d_sigma[j]*alpha);
                        if(tmp<m){
                                m=tmp;
                                d_index[i]=j;
                        }
                }
        }
		__syncthreads();
}

//======================================================================================
//usage
//======================================================================================
void usage(){
	printf("Usage: ./MetaBinG2 [FASTA file] [db] [threadNum] [outname]\n");
}

//======================================================================================
//calculate the index of kmer 
//parameters
//str:kmer
//======================================================================================
int calKmerIndex(char* str){
	int a=0;
	int n=strlen(str);
	int tmp=0;
	//order A T C G
	for(int i=0;i<n;i++){
		switch(str[i]){
			case 'A':
				tmp=0;
				break;
			case 'a':
				tmp=0;
				break;	
			case 'T':
				tmp=1;
				break;
			case 't':
				tmp=1;
				break;
			case 'C':
				tmp=2;
				break;
			case 'c':
				tmp=2;
				break;
			case 'G':
				tmp=3;
				break;
			case 'g':
				tmp=3;
				break;
			default:
				;	
		}
		a=a*4+tmp;
	}
	
	return a;
}

//======================================================================================
//count kmer of a seq
//parameters: 
//seq: atcg sequences
//kmer: size of kmer
//frag: a temp variant used to store kmers
//======================================================================================
void countKmer(char* seq,int kmer,char* frag,float* seqm,int buffi,int seqvlen){
	for(int i=0;i<strlen(seq)-kmer+1;i++){
		int legal=1;
		for(int j=0;j<kmer;j++){
			if(seq[i+j]!='A' && seq[i+j]!='T' && seq[i+j]!='C' && seq[i+j]!='G' && seq[i+j]!='a' && seq[i+j]!='t' && seq[i+j]!='c' && seq[i+j]!='g'){
				legal=0;
			}
		}
		if(legal==1){
	                strncpy(frag,seq+i,kmer);
			seqm[calKmerIndex(frag)+buffi*seqvlen]+=1;
		}
	}
}

//======================================================================================
//do matrix multiplication on GPU
//parameters
//scorelist:mrow*buff matrix
//d_scorelist:gpu scorelist
//seqm:buff*seqvlen matrix
//d_seqm:gpu seqm
//d_datad:  the numberic part of the db file,mrow*seqvlen matrix
//======================================================================================

int matMultiplication(int mrow,int buff,float* scorelist,float* d_scorelist,int seqvlen,float* seqm,float* d_seqm,float* d_datad, char ** datas,char** titlel,float* sigmaG,int* statsNum,int flag,float alpha,float* d_sigmaG,int* d_index,int* index,int buffi,FILE *fp){
	cublasStatus status;

    status=cublasSetVector(mrow*buff, sizeof(float), scorelist, 1, d_scorelist, 1);
    if (status != CUBLAS_STATUS_SUCCESS) {
            fprintf (stderr, "device access error.\n");
        return EXIT_FAILURE;
    }

    status=cublasSetVector(seqvlen*buff, sizeof(float), seqm, 1, d_seqm, 1);
    if (status != CUBLAS_STATUS_SUCCESS) {
        fprintf (stderr, "device access error.\n");
        return EXIT_FAILURE;
    }

    cublasSgemm('t', 'n', buff, mrow, seqvlen, 1.0f, d_seqm, seqvlen, d_datad, seqvlen, 0.0, d_scorelist, buff);

    int readNum;

	cudaMemcpy(d_sigmaG,sigmaG,sizeof(float)*mrow,cudaMemcpyHostToDevice);
	
	dim3 grid(ceil((buff+127)/128),1,1);
	dim3 block(128,1,1);
	parallel<<<grid,block>>>(d_scorelist,d_sigmaG,d_index,buff,mrow,alpha);
	
	cudaMemcpy(index,d_index,sizeof(int)*buff,cudaMemcpyDeviceToHost);

	if(buffi==0){
		readNum=buff;
	}else{
		readNum=buffi;
	}	

	for(int i=0;i<readNum;i++){
        statsNum[index[i]]++;    
		if(flag){
            fprintf(fp,"%s",titlel[i]);
            for(int j=6;j>=0;j--){
                fprintf(fp,"\t%s",datas[7*index[i]+j]);
            }
            fprintf(fp,"\n");
        }
		
    }
	
    return 0;
}

void *classFun(void *arg){
	int ci=*(int *)arg;

    int i,j;
    char* line;
    line=(char*)malloc((10000+(kmer+2))*seqvlen*sizeof(char));
    memset(line,0,(10000+(kmer+2)*seqvlen));

    int buffi=0;

    char* seq=(char*)malloc((10000+(kmer+2))*seqvlen*sizeof(char));
    float* seqm=(float*)malloc(sizeof(float)*seqvlen*buff);
    for(int i=0;i<seqvlen*buff;i++){
			seqm[i]=0;
	}
	float* d_seqm=0;
	cublasAlloc(seqvlen*buff,sizeof(float),(void**)&d_seqm);

	char* title=(char*)malloc(sizeof(char)*1000);
	char** titlel=(char**)malloc(buff*sizeof(char*));
	for(int i=0;i<buff;i++){
		titlel[i]=(char*)malloc((1000)*sizeof(char));
	}
	char* frag;
	frag=(char*)malloc(sizeof(char)*10);
	float* scorelist=(float*)malloc(buff*mrow*sizeof(float));
	float* d_scorelist = 0;
	cublasAlloc(mrow*buff, sizeof(float),(void**)&d_scorelist);		

	int *index=(int*)malloc(sizeof(int)*buff);
	int *d_index;
	cudaMalloc((void**)&d_index,sizeof(int)*buff);

	int *statsNumthread=(int *)malloc(mrow*sizeof(int));

	for(i=0;i<mrow;i++){
		statsNumthread[i]=0;
	}

	char** datas_fun=(char**)malloc(7*mrow*sizeof(char*));
	for(i=0;i<mrow;i++){
		for(j=0;j<7;j++){
			datas_fun[i*7+j]=(char*)malloc((strlen(datas[i*7+j])+1)*sizeof(char));
			strcpy(datas_fun[i*7+j],datas[i*7+j]);
		}
	}

	float* datad_fun=(float*)malloc((mcolmax-7)*mrow*sizeof(float));
	memcpy(datad_fun,datad,sizeof(float)*mrow*(mcolmax-7));
	float* d_datad=0;
	cublasAlloc(mrow*(mcolmax-7), sizeof(float),(void**)&d_datad);
	cublasSetVector(mrow*(mcolmax-7), sizeof(float), datad_fun, 1, d_datad, 1);

	float *sigmaG_fun=(float*)malloc(mrow*sizeof(float));
	memcpy(sigmaG_fun,sigmaG,sizeof(float)*mrow);
	float *d_sigmaG;
	cudaMalloc((void**)&d_sigmaG,sizeof(float)*mrow);


	FILE *fp=fopen(tmp[ci],"r");
	FILE *fp1=fopen(tmp1[ci],"w+");

    while(fgets(line,(10000+(kmer+2)*seqvlen),fp)!=NULL){
            line[strlen(line)-1]='\0';
            if(line[0]=='>'){
					if(title[0]=='>'){
						countKmer(seq,kmer,frag,seqm,buffi,seqvlen);
						strcpy(titlel[buffi],title);
						
						buffi++;
						if(buffi==buff){
							buffi=0;
							for(int i=0;i<buff*mrow;i++){
								scorelist[i]=0;
							}				   
							matMultiplication(mrow,buff,scorelist,d_scorelist,seqvlen,seqm,d_seqm,d_datad,datas_fun,titlel,sigmaG_fun,statsNumthread,flag,alpha,d_sigmaG,d_index,index,buffi,fp1);
							for(int i=0;i<seqvlen*buff;i++){
								seqm[i]=0;
							}
						}
					}
					memset(title,0,1000);
					strcpy(title,line);
					memset(seq,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
					memset(line,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));			
				}else{
					strcpy(seq,strcat(seq,line));
				}

    }

    fclose(fp);
    if(title[0]=='>'){
		countKmer(seq,kmer,frag,seqm,buffi,seqvlen);
		strcpy(titlel[buffi],title);
		buffi++;
		for(int i=0;i<buff*mrow;i++){
					scorelist[i]=0;
		}

		matMultiplication(mrow,buff,scorelist,d_scorelist,seqvlen,seqm,d_seqm,d_datad,datas_fun,titlel,sigmaG_fun,statsNumthread,flag,alpha,d_sigmaG,d_index,index,buffi,fp1);
		memset(title,0,1000);
		memset(seq,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
		memset(line,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
	}

    for(i=0;i<mrow;i++){
            statsNum[ci*mrow+i]=statsNumthread[i];
    }

    fclose(fp1);

    free(index);				
	cudaFree(d_index);
	cudaFree(d_sigmaG);
	cudaFree(d_datad);
	for(int i=0;i<buff;i++){free(titlel[i]);}
	for(int i=0;i<7*mrow;i++){free(datas_fun[i]);}
	free(line);			
	free(title);			
	free(seq);
	cublasFree(d_seqm);
	free(frag);
	free(scorelist);
	cublasFree(d_scorelist);
	free(seqm);


    return ((void *)0);	
}

int main(int argc,char ** argv){
	if(argc==5){
		long long start=getSystemTime();

		cublasStatus status;
		status = cublasInit();
		if (status != CUBLAS_STATUS_SUCCESS) {
				fprintf (stderr, "CUBLAS initialization error.\n");
	        	return EXIT_FAILURE;
	    	}
		int mcol=0;
		mrow=0;
		mcolmax=0;
		buff=1000;
		//alpha=atof(argv[3]);
		alpha=0.0002;
		threadNum=atoi(argv[3]);

		//if(!alpha>0){
			//alpha=0.0002;
		//}
		if(!threadNum>0){
			threadNum=4;
		}else if(threadNum>16){
			threadNum=4;
		}

		printf("You selected %d threads.\n",threadNum);

		tmp=(char**)malloc(threadNum*sizeof(char*));
		tmp1=(char**)malloc(threadNum*sizeof(char*));

		for(int i=0;i<threadNum;i++){
			tmp[i]=(char*)malloc(100*sizeof(char));
			tmp1[i]=(char*)malloc(100*sizeof(char));
			sprintf(tmp[i],"%s_tmp_%d",argv[4],i);
			sprintf(tmp1[i],"%s_tmpw_%d",argv[4],i);
		}


		//======================================================================================
		//read the dbfile to determine the number of rows and cols
		//======================================================================================
		FILE *fp1;
		char ch;
		const char* db=NULL;
		db=argv[2];
		//if(argc==2){db="db";}
		fp1=fopen(db,"r");
		if(fp1==NULL){
			printf("The db file does not exist!\n");exit(1);
		}
		while((ch=fgetc(fp1))!=EOF){
			switch(ch){
				case '\t':
					mcol++;
					break;
				case '\n':
					mrow++;
					if(mcol>mcolmax){
						mcolmax=mcol;
					}
					mcol=0;
					break;
				default:
					break;
			}		
		}
		mcolmax++;
		kmer=0;
		int ncoltemp=mcolmax-7;
		while(ncoltemp>=4){
			ncoltemp=ncoltemp/4;
			kmer++;
		}
		if(ncoltemp!=1){
			printf("%s","The db file format is not correct!\n");
			exit(1);
		}
		seqvlen=(unsigned int)pow(4.0,kmer);
		fclose(fp1);

		//======================================================================================
		//read the dbfile again to get the taxonomy information and the transition probabilities
		//======================================================================================
		datas=(char**)malloc(7*mrow*sizeof(char*));

		datad=(float*)malloc((mcolmax-7)*mrow*sizeof(float));

		FILE *refp1;
		refp1=fopen(db,"r");
		char* line;
		int trow=0;
		int tcol=0;
		line=(char*)malloc((10000+(kmer+2)*((unsigned int)pow(4.0,kmer)))*sizeof(char));
		memset(line,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
		while(fgets(line,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))),refp1)!=NULL){
			line[strlen(line)-1]='\0';
			char* p;
			for(p=strtok(line,"\t\n");p;p=strtok(NULL,"\t\n")){
				if(tcol<7){
					datas[trow*7+tcol]=(char*)malloc((strlen(p)+1)*sizeof(char));
					strcpy(datas[trow*7+tcol],p);
				}else{
					datad[trow*(mcolmax-7)+tcol-7]=atof(p);
				}
				tcol++;
				if(tcol==mcolmax){
					trow++;
					tcol=0;
				}
			}
			memset(line,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
		}
		fclose(refp1);

		//======================================================================================
		//divide the sequence file into 4 tmp file
		//======================================================================================
		FILE *fseq;

		FILE *fseqt[16];

        fseq=fopen(argv[1],"r");

        for(int i=0;i<threadNum;i++){
        	fseqt[i]=fopen(tmp[i],"w+");
        }

        
        memset(line,0,(10000+(kmer+2)*((unsigned int)pow(4.0,kmer))));
        long int readNum=0;
        while(fgets(line,(10000+(kmer+2)*4096),fseq)!=NULL){
                readNum++;
        }

        fclose(fseq);

		long int tnum=readNum/threadNum+1;
		if(tnum%2!=0){
			tnum++;
		}

		fseq=fopen(argv[1],"r");

		long int num=0;

		while(fgets(line,(10000+(kmer+2)*4096),fseq)!=NULL){
                num++;
                	line[strlen(line)-1]='\0';
			 		if(num<=tnum){
	                    fprintf(fseqt[0],"%s\n",line);
	                }
	                else if(num<=tnum*2){
	                    fprintf(fseqt[1],"%s\n",line);
	                }else if(num<=tnum*3){
	                 	fprintf(fseqt[2],"%s\n",line);
	                }else if(num<=tnum*4){
	                 	fprintf(fseqt[3],"%s\n",line);
	                }else if(num<=tnum*5){
	                 	fprintf(fseqt[4],"%s\n",line);
	                }else if(num<=tnum*6){
	                 	fprintf(fseqt[5],"%s\n",line);
	                }else if(num<=tnum*7){
	                 	fprintf(fseqt[6],"%s\n",line);
	                }else if(num<=tnum*8){
	                 	fprintf(fseqt[7],"%s\n",line);
	                }else if(num<=tnum*9){
	                 	fprintf(fseqt[8],"%s\n",line);
	                }else if(num<=tnum*10){
	                 	fprintf(fseqt[9],"%s\n",line);
	                }else if(num<=tnum*11){
	                 	fprintf(fseqt[10],"%s\n",line);
	                }else if(num<=tnum*12){
	                 	fprintf(fseqt[11],"%s\n",line);
	                }else if(num<=tnum*13){
	                 	fprintf(fseqt[12],"%s\n",line);
	                }else if(num<=tnum*14){
	                 	fprintf(fseqt[13],"%s\n",line);
	                }else if(num<=tnum*15){
	                 	fprintf(fseqt[14],"%s\n",line);
	                }else{
	                 	fprintf(fseqt[15],"%s\n",line);
	                }
                
		
        }

        fclose(fseq);

        for(int i=0;i<threadNum;i++){
        	fclose(fseqt[i]);
        }

	    sigmaG=(float *)malloc(mrow*sizeof(float));
	    float *percentl=(float *)malloc(mrow*sizeof(float));

		for(int i=0;i<mrow;i++){
			sigmaG[i]=(float)mrow;
			percentl[i]=10;
		}

		//set cutoff
		float stop=0.1;

		flag=0;

		statsNum=(int *)malloc(mrow*threadNum*sizeof(int));


	    for(int t=0;t<10;t++){

	    	for(int i=0;i<mrow*threadNum;i++){
				statsNum[i]=0;
			}

			float BC=0;

	    	if(t>=9){
	    		flag=1;
	    	}
			
			//======================================================================================
			//1.read (buff) fasta sequences 
			//2.convert them into numeric vectors 
			//3.copy the vectors to GPU
			//4.do matrix multiplication with d_datad on GPU
			//5.get the result from the GPU
			//6.interpret the result
			//======================================================================================

	    	//multi-threads for reading fasta file
	    	pthread_t thread[16];
	    	int si[16]={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15};
	        memset(&thread,0,sizeof(thread));

	        int i;

	        for(i=0;i<threadNum;i++){
	                int ci=si[i];
	                if(pthread_create(&thread[ci],NULL,&classFun,&si[i])!=0){
	                        printf("create thread error!\n");
	                }
	        }
	        int counter=0;
	        int wait=0;
	        int ti;

	        while(counter<threadNum){
	                wait++;

	                for(ti=0;ti<threadNum;ti++){
	                        if(thread[ti]!=0){
	                                pthread_join(thread[ti],NULL);
	                                counter++;
	                        }
	                }
	        }

	        

	        counter=0;

			if(flag){
				break;
			}else{
				//update sigma with statsNum
				int statsNumsum;

				int readscount=readNum/2;
				for(int i=0;i<mrow;i++){
					statsNumsum=0;
					for(int j=0;j<threadNum;j++){
						statsNumsum=statsNumsum+statsNum[j*mrow+i];
					}
					if(statsNumsum>0){
						
						sigmaG[i]=(float)readscount/(float)statsNumsum;
						BC=BC+pow(((float)statsNumsum/(float)readscount-percentl[i]),2);
						percentl[i]=(float)statsNumsum/(float)readscount;
					}else{
						sigmaG[i]=1e10;
						BC=BC+pow((0-percentl[i]),2);
						percentl[i]=0;
					}
				}
				printf("j:%d;BC:%.4f\n",j,BC);
				if(BC<stop){
					flag=1;
				}

			}
			
		}

		free(sigmaG);
		free(percentl);
		free(statsNum);
		for(int i=0;i<7*mrow;i++){free(datas[i]);}			
		free(datad);		

		char cmd[100];
		sprintf(cmd,"cat %s_tmpw_* >%s",argv[4],argv[4]);
		system(cmd);

		char cmd1[100];
		sprintf(cmd1,"rm %s_tmp*",argv[4]);
		system(cmd1);


		long long end=getSystemTime();
        printf("time:%lld ms\n",end-start);

		return 0;
	}else{
		usage();
		return -1;
	}
}
