/* File: dynamics.c
 * Purpose: Implementa la dinamica evolutiva nodo a nodo (imitacion/transicion).
 */

#include <stdint.h>
#include <math.h>
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

/*funcion para decidir la probabilidad de copia. si fermi o lineal*/
static double copy_prob(double D, double K)
{
#if UPDATE_RULE==1
    double x;
    if(K<=0.0) return 0.0;
    x=FERMI_BETA*D/K;
    if(x>50.0) return 1.0; /* evita overflow numerico en exp */
    if(x<-50.0) return 0.0;
    return 1.0/(1.0+exp(-x));
#elif UPDATE_RULE==0
    if(D<=0.0) return 0.0;
    if(K<=0.0) return 0.0;
    return D/K;
#else
#error "UPDATE_RULE debe ser 0 (lineal) o 1 (Fermi)."
#endif
}

/*probabilidad de que i copie a j. (i,j de la misma poblacion)*/
double Pij(int i, int j, const Graph *g, params lambda, u_min_max u, const uint8_t *gamma)
{
    double D,K;
    K=g->k_intra[j]*u.u_intra_max+g->k_inter[j]*u.u_inter_max-(g->k_intra[i]*u.u_intra_min+g->k_inter[i]*u.u_inter_min);
    D=delta_ij(i,j,gamma,lambda,g);
    return copy_prob(D,K);
}

/*optimizacion nueva ahora ya no utiliza algunas de las funciones anteriores y no
recalculamos los pagos 2 veces en cada paso temporal, para cada nodo*/
void time_step(const uint8_t *gamma_old,uint8_t *gamma_new, const Graph *g, params lambda, u_min_max u)
{
    int i,j,d;
    double payoff[NTOT];
    double D,P,K;

    for(i=0;i<NTOT;i++) 
        payoff[i]=Pi_i(i,gamma_old,lambda,g);

    for(i=0;i<NTOT;i++)
    {
        if(g->k_intra[i]!=0)
        {
            d=rng_int(g->k_intra[i]);
            j=g->col_idx[g->row_ptr[i]+d];
            D=payoff[j]-payoff[i];
            K=g->k_intra[j]*u.u_intra_max+g->k_inter[j]*u.u_inter_max-(g->k_intra[i]*u.u_intra_min+g->k_inter[i]*u.u_inter_min);
            P=copy_prob(D,K);

            if(P>fran()) gamma_new[i]=gamma_old[j];
            else gamma_new[i]=gamma_old[i];
        }
        else gamma_new[i]=gamma_old[i];
    }
}
