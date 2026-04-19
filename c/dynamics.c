/* File: dynamics.c
 * Purpose: Implementa la dinamica evolutiva nodo a nodo (imitacion/transicion).
 */

#include <stdint.h>
#include "types.h"
#include "rng.h"
#include "payoff.h"

#define MAX(a,b) ((a)>(b)?(a):(b))
#define MIN(a,b) ((a)<(b)?(a):(b))


/*calcula las cotas para los pagos 1 a 1 en funcion del vector de parametros lambda*/
void u_bounds(params lambda, u_min_max *u)
{
    u->u_intra_max=MAX(1.0,MAX(lambda.b,lambda.r));
    u->u_intra_min=MIN(0.0,MIN(lambda.b,lambda.r));
    u->u_inter_max=MAX(1.0,MAX(lambda.b,lambda.e));
    u->u_inter_min=MIN(0.0,MIN(lambda.b,lambda.e));
}

/*probabilidad de que i copie a j. (i,j de la misma poblacion)*/
double Pij(int i, int j, const Graph *g, params lambda, u_min_max u, const uint8_t *gamma)
{
    double P,D,K=g->k_intra[j]*u.u_intra_max+g->k_inter[j]*u.u_inter_max-(g->k_intra[i]*u.u_intra_min+g->k_inter[i]*u.u_inter_min);
    D=delta_ij(i,j,gamma,lambda,g);
    if(D<=0) P=0;
    else P=D/K;
    return P;
}

void time_step(uint8_t *gamma, const Graph *g, params lambda, u_min_max u)
{
    int i,j,d,valid=0;
    while(valid<NTOT)
    {
        i=rng_int(NTOT);
        if(g->k_intra[i]!=0)
        {
            d=rng_int(g->k_intra[i]);
            j=g->col_idx[g->row_ptr[i]+d];
            if(Pij(i,j,g,lambda,u,gamma)>fran()) gamma[i]=gamma[j];
            valid++;
        }
    }
}