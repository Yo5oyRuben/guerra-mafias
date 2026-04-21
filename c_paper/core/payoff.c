/* File: payoff.c
 * Purpose: Implementa el calculo de pagos segun estrategias y estructura de red.
 */
#include <stdint.h>
#include "graph.h"
#include "types.h"

/*calcula pagos de encuentros 1 a 1 para individuos dentro de la misma poblacion*/
double u_intra(uint8_t si, uint8_t sj, params lambda)
{
    return (double)(si*sj+lambda.b*(1-si)*sj+lambda.r*(1-si)*(1-sj));
}

/*calcula pagos de encuentros 1 a 1 para individuos de diferentes poblaciones*/
double u_inter(uint8_t si, uint8_t sl, params lambda)
{
    return (double)(si*sl+lambda.b*(1-si)*sl+lambda.e*(1-si)*(1-sl));
}

/*calcula el pago total para un individuo i, sea de la poblaicon 1 o 2*/
double Pi_i(int i, const uint8_t *gamma, params lambda, const Graph *g)
{
    int k,j;
    double pi=0;
    for(k=g->row_ptr[i];k<g->row_ptr[i+1];k++)
    {
        j=g->col_idx[k];
        if((i<N1&&j<N1)||(i>=N1&&j>=N1))
        {
            pi+=u_intra(gamma[i],gamma[j],lambda);
        }
        else
        {
            pi+=u_inter(gamma[i],gamma[j],lambda);
        }
    }
    return pi;
}

/*calcula la diferencia de pagos entre dos individuos i,j, sean de las poblaciones 1 o 2*/
double delta_ij(int i, int j, const uint8_t *gamma, params lambda, const Graph *g)
{
    return Pi_i(j,gamma,lambda,g)-Pi_i(i,gamma,lambda,g);
}
