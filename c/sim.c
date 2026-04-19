/* File: sim.c
 * Purpose: Implementa ejecucion de experimentos, barridos temporales y estadisticas.
 */
#include "config.h"
#include "dynamics.h"
#include "state.h"

void time_loop(uint8_t *gamma, const Graph *g,params lambda, u_min_max u,
                double *xc_1, double *xc_2)
{
    int i;

    for(i=0;i<T_RELAX;i++) time_step(gamma,g,lambda,u);
    for(i=0;i<T_MCS;i++)
    {
        time_step(gamma, g, lambda, u);
        xc_1[i]=xc1(gamma);
        xc_2[i]=xc2(gamma);
    }
}