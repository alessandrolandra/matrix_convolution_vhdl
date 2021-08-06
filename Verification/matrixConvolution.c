#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "string.h"

#define M 16//rows and columns of the in_matrix
#define K 3//rows and columns of the kernel

int FIXED_POINT_FRACTIONAL_BITS=16;
const char path[]="C:\\Users\\Alessandro\\Documents\\Poli\\SpecificationAndSimulationOfDigitalSystems\\assignment\\matrixConvolution\\Verification\\files\\";

void initPaddedMatrix(ulong** matrix,FILE *f);
void initKernel(ulong** kernel,FILE *f);
void computeConvolution(ulong** matrix,ulong** kernel,FILE *f);
void toBin(ulong in, char *out, int sizeIn, int sizeOut);
double toDouble(const char *in,int bitInt,int bitDec);
void toFixedPointBin(double in, char *out, int size);

int main() {
    FILE *f;
    int i;
    char filePath[100];
    ulong **matrix,**kernel;

    matrix=malloc((M+2)*sizeof(ulong*));
    for(i=0;i<(M+2);i++){
        matrix[i]=calloc((M+2),sizeof(ulong));
    }
    kernel=malloc(K*sizeof(ulong*));
    for(i=0;i<K;i++){
        kernel[i]=malloc(K*sizeof(ulong));
    }

    strcpy(filePath,path);
    strcat(filePath,"matrixIn.mem");
    f=fopen(filePath,"w");
    initPaddedMatrix(matrix,f);
    fclose(f);
    strcpy(filePath,path);
    strcat(filePath,"invertedKernel.mem");
    f=fopen(filePath,"w");
    initKernel(kernel,f);
    fclose(f);
    strcpy(filePath,path);
    strcat(filePath,"matrixOut.mem");
    f=fopen(filePath,"w");
    computeConvolution(matrix,kernel,f);
    fclose(f);
    return 0;
}

void initPaddedMatrix(ulong** matrix,FILE *f){
    int i,k,j;
    ulong x;
    char c[33];
    double d;
    printf("PADDED MATRIX\n");
    for(i=0;i<(M+2);i++) {
        if (i == 0 || i == (M+1)) {
            for(j=0;j<(M+2);j++) {
                printf("%11.5f ",0.0);
            }
        } else {
            for (k = 0; k < (M+2); k++) {
                if (k == 0 || k == (M+1)) {
                    printf("%11.5f ",0.0);
                } else {
                    x = (ulong) random();
                    matrix[i][k] = x;
                    toBin(x, c, 32, 32);
                    fprintf(f, "%s ", c);
                    d = toDouble(c, 16, 16);
                    printf("%11.5f ", d);
                }
            }
            fprintf(f,"\n");
        }
        printf("\n");
    }
    printf("----------------------------------------------------------------------\n\n");
}

void initKernel(ulong** kernel,FILE *f){
    int i,k;
    ulong x;
    char c[33];
    double d;
    printf("INVERTED KERNEL\n");
    for(i=0;i<K;i++){
        for(k=0;k<K;k++) {
            x=(ulong)random();
            kernel[i][k]=x;
            toBin(x,c,32,32);
            fprintf(f,"%s ",c);
            d=toDouble(c,16,16);
            printf("%11.5f ",d);
        }
        fprintf(f,"\n");
        printf("\n");
    }
    printf("----------------------------------------------------------------------\n\n");
}

void computeConvolution(ulong** matrix,ulong** kernel,FILE *f){
    int i,j,k,l;
    ulong sum;
    char s[65],s2[65];
    double d;
    printf("CONVOLUTION RESULT\n");
    for(i=0;i<M;i++){
        for(j=0;j<M;j++) {
            sum=0;
            for(k=0;k<K;k++) {
                for(l=0;l<K;l++) {
                    sum+=matrix[i+k][j+l]*kernel[k][l];
                }
            }
            toBin(sum,s,64,48);
            fprintf(f, "%s ", s);
            d=toDouble(s,32,16);
            toFixedPointBin(d,s2,48);
            printf("%s ( -> %.5f -> %s) | ",s,d,s2);
        }
        fprintf(f,"\n");
        printf("\n");
    }
}

/**
 * writes in 'out' the unsigned binary representation of the ulong number 'in'
 * @param in
 * @param out
 * @param sizeIn
 * @param sizeOut
 */
void toBin(ulong in, char *out, int sizeIn, int sizeOut){
    int i = 0;
    char binaryNum[sizeIn],str[sizeOut + 1];
    while (in > 0) {
        binaryNum[i++] = in%2==0?'0':'1';
        in = in / 2;
    }
    for(; i < sizeIn; i++)
        binaryNum[i]='0';
    for (i=(sizeIn - 1); i >= (sizeIn - sizeOut); i--)
        str[sizeIn - 1 - i]=binaryNum[i];
    str[sizeOut]='\0';
    strcpy(out,str);
}

/**
 * writes in 'out' the fixed point binary representation of the double number 'in', with FIXED_POINT_FRACTIONAL_BITS related to the fractional part
 * @param in
 * @param out
 * @param size: wanted bit-width of the result
 */
void toFixedPointBin(double in, char *out, int size){
    int i = 0;
    ulong n;
    char binaryNum[size],str[size + 1];
    n = in * (1 << FIXED_POINT_FRACTIONAL_BITS);
    while (n > 0) {
        binaryNum[i++] = n%2==0?'0':'1';
        n = n / 2;
    }
    for(; i < size; i++)
        binaryNum[i]='0';
    for (i=(size - 1); i >= 0; i--)
        str[size - 1 - i]=binaryNum[i];
    str[size]='\0';
    strcpy(out,str);
}

/**
 * returns the conversion to double of the 'in' binary number, according to the other parameters
 * @param in
 * @param bitInt: number of bit related to the integer part
 * @param bitDec: number of bit related to the fractional part
 * @return
 */
double toDouble(const char *in,int bitInt,int bitDec){
    int i = bitInt-1;
    double sum=0;
    while (i > -bitDec) {
        if(in[bitInt-1-i]=='1'){
            sum+=pow(2,i);
        }
        i--;
    }
    sum=trunc(100000*sum)/100000;//to force 5 decimal digits
    return sum;
}