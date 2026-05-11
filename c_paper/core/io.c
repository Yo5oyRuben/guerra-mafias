#include <stdio.h>
#include "types.h"

/*aqui implementamos funciones sencillas de entrada y salida que usamos durante procesos
simulacion y debugging*/

/*guardar un vector normal en un fichero*/
void print_vector(double *v, int n, char *filename)
{
    int i;
    FILE *out=fopen(filename,"w");
    if(out==NULL) return;

    for(i=0;i<n;i++) fprintf(out,"%d\t%f\n",i,v[i]);
    
    fclose(out);
}

/*guardar los resultados de c_med y su error para
un barrido de b, a p12 y el resto de parametros ctes*/
void print_c_p12(double *c_med,double *c_sigma,double *b_values,double p12, char *filename)
{
    int i;
    FILE *out=fopen(filename,"a");
    if(out==NULL) return;

    fprintf(out,"%f\n",p12);
    for(i=0;i<NDIV;i++) fprintf(out,"%f\t%f\t%f\n",b_values[i],c_med[i],c_sigma[i]);
    fprintf(out,"\n");

    fclose(out);
}
