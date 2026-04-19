/* File: sim.c
 * Purpose: Implementa ejecucion de experimentos, barridos temporales y estadisticas.
 */

#include <math.h>
#include "config.h"
#include "dynamics.h"
#include "state.h"
#include "utils.h"

#if SAVE_SERIES
void time_loop(uint8_t *gamma, const Graph *g,params lambda, u_min_max u,
                double *xc_1, double *xc_2, int *N_control, 
                double *xc_1_med, double *xc_2_med,
                double *xc_1_sigma, double *xc_2_sigma)
{
    int j,i;
    double epsilon1,epsilon2,aux;
    double W_med_sigma[8]={0};

    /*detectar cuando xc alcanza un valor estable*/
    i=0;
    while(i<T_MAX)
    {
        time_step(gamma,g,lambda,u);
        xc_1[i]=xc1(gamma);
        xc_2[i]=xc2(gamma);
        i++;
        if(i%W==0)
        {
            medvar(xc_1+i-W,W,W_med_sigma+4,W_med_sigma+5);
            medvar(xc_2+i-W,W,W_med_sigma+6,W_med_sigma+7);
            epsilon1=3*W_med_sigma[5]/sqrt(W);
            epsilon2=3*W_med_sigma[7]/sqrt(W);
            if(fabs(W_med_sigma[0]-W_med_sigma[4])<epsilon1
                &&fabs(W_med_sigma[2]-W_med_sigma[6])<epsilon2
                &&i>=2*W)
                break;
            else
            {
                for(j=0;j<=3;j++)
                {
                    aux=W_med_sigma[j];
                    W_med_sigma[j]=W_med_sigma[4+j];
                    W_med_sigma[4+j]=aux;
                }
            }
        }
    }

    /*medir xc*/
    *N_control=i;
    for(j=0;j<T_MCS;j++)
    {
        time_step(gamma, g, lambda, u);
        xc_1[i+j]=xc1(gamma);
        xc_2[i+j]=xc2(gamma);
    }

    medvar(xc_1+i,T_MCS,xc_1_med,xc_1_sigma);
    medvar(xc_2+i,T_MCS,xc_2_med,xc_2_sigma);
}

#else

void time_loop(uint8_t *gamma, const Graph *g,params lambda, u_min_max u,
                double *xc_1_med, double *xc_2_med, double *xc_1_sigma, 
                double *xc_2_sigma, double *c_med, double *c_sigma)
{
    int i,j;
    double epsilon1,epsilon2,aux;
    double W_med_sigma[8]={0};
    double xc_1[W]={0}, xc_2[W]={0};
    double xc_1_measure[T_MCS]={0}, xc_2_measure[T_MCS]={0};

    /*detectar cuando xc alcanza un valor estable*/
    i=0;
    while(i<T_MAX)
    {
        time_step(gamma,g,lambda,u);
        xc_1[i%W]=xc1(gamma);
        xc_2[i%W]=xc2(gamma);
        i++;
        if(i%W==0)
        {
            medvar(xc_1,W,W_med_sigma+4,W_med_sigma+5);
            medvar(xc_2,W,W_med_sigma+6,W_med_sigma+7);
            epsilon1=3*W_med_sigma[5]/sqrt(W);
            epsilon2=3*W_med_sigma[7]/sqrt(W);
            if(fabs(W_med_sigma[0]-W_med_sigma[4])<epsilon1
                &&fabs(W_med_sigma[2]-W_med_sigma[6])<epsilon2
                &&i>=2*W)
                break;
            else
            {
                for(j=0;j<=3;j++)
                {
                    aux=W_med_sigma[j];
                    W_med_sigma[j]=W_med_sigma[4+j];
                    W_med_sigma[4+j]=aux;
                }
            }
        }
    }

    /*medir xc*/
    for(i=0;i<T_MCS;i++)
    {
        time_step(gamma, g, lambda, u);
        xc_1_measure[i]=xc1(gamma);
        xc_2_measure[i]=xc2(gamma);
    }

    medvar(xc_1_measure,T_MCS,xc_1_med,xc_1_sigma);
    medvar(xc_2_measure,T_MCS,xc_2_med,xc_2_sigma);
    
    *c_med=0.5*(*xc_1_med+*xc_2_med);
    *c_sigma=0.5*sqrt(*xc_1_sigma**xc_1_sigma+*xc_2_sigma**xc_2_sigma);
}

#endif
