/* File: payoff.c
 * Purpose: Implementa el calculo de pagos segun estrategias y estructura de red.
 */
#include <stdint.h>
#include "graph.h"
#include "types.h"

/*calcula pagos de encuentros 1 a 1 para individuos dentro de la misma poblacion*/
double u_intra(uint8_t si, uint8_t sj, double qi, double qj)
{
    return (double)(qj*si*sj-qi*(1-si)*sj+qj*(1-si)*(1-sj));
}

/*calcula el pago total para un individuo i, sea de la poblaicon 1 o 2*/
double Pi_i(int i, const uint8_t *gamma, const Graph *g)
{
    int k,j,k0,kin,max_k;
    double pi=0;
    k0=g->row_ptr[i];
    kin=g->k_intra[i];
    if(i<N1) max_k=g->max_k_intra1;
    else max_k=g->max_k_intra2;

    for(k=k0;k<k0+kin;k++)
    {
        j=g->col_idx[k];
        pi+=u_intra(gamma[i],gamma[j],1+(double)kin/max_k,1+(double)g->k_intra[j]/max_k);
    }
    return pi;
}

/*calcula la diferencia de pagos entre dos individuos i,j, sean de las poblaciones 1 o 2*/
double delta_ij(int i, int j, const uint8_t *gamma, const Graph *g)
{
    return Pi_i(j,gamma,g)-Pi_i(i,gamma,g);
}
