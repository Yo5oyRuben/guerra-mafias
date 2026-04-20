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
#include "payoff.h"
#include "dynamics.h"
#include "sim.h"
#include "utils.h"
#include "io.h"

int main(void)
{
    /*declarar cosas*/
    Graph g;
    params lambda;
    u_min_max u;
    uint8_t gamma[NTOT];

    int i;
    double xc_1_med,xc_2_med,xc_1_sigma,xc_2_sigma,c_med,c_sigma;
    unsigned int seed_graph=(unsigned int)time(NULL);
    unsigned int seed_state=(unsigned int)time(NULL)*2;
    double c_med_values[NDIV];
    double delta=(double)(BMAX-BMIN)/NDIV;


    lambda.b=BMIN; lambda.e=E; lambda.r=R;
    initial_ER(&g,P11,P12,P22,seed_graph);
    rng_seed(seed_state);
    ini_rand_Pr(gamma,0.5,0.5);
    u_bounds(lambda,&u);

    for(i=0;i<NDIV;i++)
    {
        ini_rand_Pr(gamma,0.5,0.5);
        time_loop(gamma, &g, lambda, u, &xc_1_med, &xc_2_med, &xc_1_sigma, &xc_2_sigma, &c_med, &c_sigma);
        c_med_values[i]=c_med;
        printf("%f\t%f\n",lambda.b,c_med);
        lambda.b+=delta;
        u_bounds(lambda, &u);
    }

        free(g.col_idx);
    return 0;
}
