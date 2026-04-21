/* File: dynamics.c
 * Purpose: Implementa la dinamica evolutiva nodo a nodo (imitacion/transicion).
 */

#include <stdint.h>
#include "types.h"
#include "rng.h"
#include "payoff.h"


/*probabilidad de que i copie a j. (i,j de la misma poblacion)*/
double Pij(int i, int j, const Graph *g, const uint8_t *gamma)
{
    double P,D,K,max_k=(i>=N1?g->max_k_intra2:g->max_k_intra1);
    K=g->k_intra[i]*(1+(double)g->k_intra[i]/max_k)+2*g->k_intra[j];
    D=delta_ij(i,j,gamma,g);
    if(D<=0) P=0;
    else P=D/K;
    return P;
}

void time_step(const uint8_t *gamma_old,uint8_t *gamma_new, const Graph *g)
{
    int i,j,d;
    for(i=0;i<NTOT;i++)
    {
        if(g->k_intra[i]!=0)
        {
            d=g->row_ptr[i]+rng_int(-g->row_ptr[i]+g->row_ptr[i+1]);
            j=g->col_idx[g->row_ptr[i]+d];
            if(Pij(i,j,g,gamma_old)>fran()) gamma_new[i]=gamma_old[j];
            else gamma_new[i]=gamma_old[i];
        }
        else gamma_new[i]=gamma_old[i];
    }
}