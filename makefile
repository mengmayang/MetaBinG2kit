all: runMetaBinG2 MetaBinG2
.PHONY:all
runMetaBinG2:runMetaBinG2.c
	gcc -o runMetaBinG2 runMetaBinG2.c io.h pthread.h
MetaBinG2:MetaBinG2.cu
	nvcc -o MetaBinG2 MetaBinG2.cu -lcudart -lcublas
