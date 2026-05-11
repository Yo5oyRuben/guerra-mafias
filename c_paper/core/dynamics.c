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

/*aqui calculamos la probabilidad de copia. la función dependerá
de UPDATE_RULE, es decir, de la regla de actualizacion: lineal, fermi o lineal en grado.
las dos primeras son funcion unicamente de la diferencia de pagos y de la constante de normalizacion.
sin embargo, para la regla de grado, se requiere informacion de los grados de los nodos.
por optimizar, definimos dos funciones diferentes, y solo se compilará una, segun como se defina
UPDATE_RULE*/
#if UPDATE_RULE!=0 && UPDATE_RULE!=1 && UPDATE_RULE!=2
#error "UPDATE_RULE debe ser 0 (lineal), 1 (Fermi) o 2 (grado)."
#endif

#if UPDATE_RULE==0 || UPDATE_RULE==1
static double copy_prob(double D, double K)
{
    /*esta primera es de fermi: Pr=1/(1+exp(-beta*D/K))*/
#if UPDATE_RULE==1
    double x;
    if(K<=0.0) return 0.0;
    x=FERMI_BETA*D/K;
    if(x>50.0) return 1.0; /*evita overflow numerico en exp*/
    if(x<-50.0) return 0.0;
    return 1.0/(1.0+exp(-x));
    /*esta es lineal Pr=D/K*/
#elif UPDATE_RULE==0
    if(D<=0.0) return 0.0;
    if(K<=0.0) return 0.0;
    return D/K;
#endif
}
#endif

#if UPDATE_RULE==2
/*esta es lineal en grado. hemos usado Pr=D/K*(k_j-<k>)/<k>*/
static double copy_prob_degree(double D, double K, double kj, double kmean)
{
    double P,factor;
    if (D<=0.0||K<=0.0||kmean<=0.0) return 0;

    factor=1.0+DEGREE_ALPHA*(kj-kmean)/kmean;
    if(factor<DEGREE_FACTOR_MIN) factor=DEGREE_FACTOR_MIN;
    if(factor>DEGREE_FACTOR_MAX) factor=DEGREE_FACTOR_MAX;

    P=(D/K)*factor;
    if(P>1) return 1.0;
    return P;
}
#endif

/*en esta funcion, implementamos el paso temporal de todo el microestado*/
void time_step(const uint8_t *gamma_old,uint8_t *gamma_new, const Graph *g, params lambda, u_min_max u)
{
    int i,j,d;
    double D,P,K;
    /*para intentar optimizar un poquito, calculamos una unica vez los pagos
    y los guardamos en este vector*/
    double payoff[NTOT];
    for(i=0;i<NTOT;i++) 
        payoff[i]=Pi_i(i,gamma_old,lambda,g);

    /*este es el bucle principal. primero recorremos cada nodo que tenga alguna conexion con 
    otro nodo de su mismo subgrafo*/
    for(i=0;i<NTOT;i++)
    {
        if(g->k_intra[i]!=0)
        {
            d=rng_int(g->k_intra[i]);
            j=g->col_idx[g->row_ptr[i]+d];
            D=payoff[j]-payoff[i];
            K=g->k_intra[j]*u.u_intra_max+g->k_inter[j]*u.u_inter_max-(g->k_intra[i]*u.u_intra_min+g->k_inter[i]*u.u_inter_min);
            #if UPDATE_RULE==2
            P=copy_prob_degree(D,K,(double)(g->k_intra[j]+g->k_inter[j]),(double)g->m/NTOT);
            #else
            P=copy_prob(D,K);
            #endif

            if(P>fran()) gamma_new[i]=gamma_old[j];
            else gamma_new[i]=gamma_old[i];
        }
        else gamma_new[i]=gamma_old[i];
    }
}
