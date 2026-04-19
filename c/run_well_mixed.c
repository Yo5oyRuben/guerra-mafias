/* File: run_well_mixed.c
 * Purpose: Punto de entrada ejecutable para correr el caso well-mixed.
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

#include "config.h"
#include "types.h"
#include "rng.h"
#include "graph.h"
#include "state.h"
#include "dynamics.h"

int io_write_x_series(const char *path, const double *x1, const double *x2, int n);

int main(void)
{
    int i,t,TOTAL_STEPS,err;
    unsigned int seed;
    Graph g;
    params lambda;
    u_min_max u;
    uint8_t gamma[NTOT];
    double *x1,*x2;
    double p11,p12,p22;

    g.col_idx=NULL;

    /* Parametros tipo paper */
    lambda.b=1.6;
    lambda.r=0.0;
    lambda.e=-0.4;

    /* ER interno con <k>~6 en cada capa, y acoplo inter-capa p12 */
    p11=6.0/(N1-1.0);
    p22=6.0/(N2-1.0);
    p12=0.02;

    seed=(unsigned int)time(NULL);

    initial_ER(&g,p11,p12,p22,seed);
    for(i=0;i<NTOT;i++) split_degrees_i(&g,i);

    rng_seed(seed+12345U);
    ini_rand_Pr(gamma,0.5,0.5);

    u_bounds(lambda,&u);

    TOTAL_STEPS=T_RELAX+T_MCS+1;
    x1=(double*)malloc((size_t)TOTAL_STEPS*sizeof(double));
    x2=(double*)malloc((size_t)TOTAL_STEPS*sizeof(double));
    if(x1==NULL||x2==NULL)
    {
        if(g.col_idx!=NULL) free(g.col_idx);
        free(x1);
        free(x2);
        return 1;
    }

    x1[0]=xc1(gamma);
    x2[0]=xc2(gamma);

    for(t=1;t<TOTAL_STEPS;t++)
    {
        time_step(gamma,&g,lambda,u);
        x1[t]=xc1(gamma);
        x2[t]=xc2(gamma);
    }

    err=io_write_x_series("build/x1x2_time_series.txt",x1,x2,TOTAL_STEPS);

    printf("seed=%u\n",seed);
    printf("params: b=%.3f r=%.3f e=%.3f p11=%.3f p12=%.3f p22=%.3f\n",lambda.b,lambda.r,lambda.e,p11,p12,p22);
    printf("series file: build/x1x2_time_series.txt\n");
    if(err!=0) printf("warning: no se pudo escribir el fichero de salida\n");

    free(x1);
    free(x2);
    if(g.col_idx!=NULL) free(g.col_idx);

    return (err==0)?0:2;
}
