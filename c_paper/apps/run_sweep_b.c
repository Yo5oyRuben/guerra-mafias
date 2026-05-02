#include "../head.h"

/*hace un sweep desde bmin hasta bmax (defines) en saltitos controlados por NDIV.
p12 es variable y se le pasa como argumento. devuelve el vector de valores de c y
su incertidumbre para cada b*/
void sweep_b(double p12,double *c_med_values, double *c_sigma_values, double *b_values)
{
    /*declarar cosas*/
    Graph g;
    params lambda;
    u_min_max u;
    uint8_t gamma_new[NTOT], gamma_old[NTOT];

    int i;
    double xc_1_med,xc_2_med,xc_1_sigma,xc_2_sigma,c_med,c_sigma;
    unsigned int seed_graph=(unsigned int)time(NULL);
    unsigned int seed_state=(unsigned int)time(NULL)*2;
    double delta=(double)(BMAX-BMIN)/NDIV;

    /*inicializar cosas*/
    lambda.b=BMIN; lambda.e=E; lambda.r=R;
    initial_ER(&g,P11,p12,P22,seed_graph);
    rng_seed(seed_state);
    ini_rand_Pr(gamma_old,0.5,0.5);
    u_bounds(lambda,&u);

    /*barrido en b a r, e fijos*/
    for(i=0;i<NDIV;i++)
    {
        ini_rand_Pr(gamma_old,0.5,0.0);
        time_loop(gamma_old,gamma_new, &g, lambda, u, &xc_1_med, &xc_2_med, &xc_1_sigma, &xc_2_sigma, &c_med, &c_sigma);
        c_med_values[i]=xc_1_med;
        c_sigma_values[i]=xc_1_sigma;
        b_values[i]=lambda.b;
        lambda.b+=delta;
        u_bounds(lambda, &u);
    }
    free(g.col_idx);
}
