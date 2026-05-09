#include "../../head.h"
#include <math.h>
#include <string.h>

static void usage(const char *prog)
{
    fprintf(stderr,
            "Uso: %s OUTFILE P12 X01 X02 BMIN BMAX REPS SEED\n"
            "Escribe columnas: b x1_mean x1_sem x2_mean x2_sem c_mean c_sem\n",
            prog);
}

static void accum(double x, double *sum, double *sum2)
{
    *sum += x;
    *sum2 += x * x;
}

static void mean_sem(double sum, double sum2, int n, double *mean, double *sem)
{
    double var;
    *mean = sum / (double)n;
    if(n > 1)
    {
        var = (sum2 - sum * sum / (double)n) / (double)(n - 1);
        if(var < 0.0) var = 0.0;
        *sem = sqrt(var / (double)n);
    }
    else
    {
        *sem = 0.0;
    }
}

int main(int argc, char **argv)
{
    const char *outfile;
    double p12, x01, x02, bmin, bmax, delta;
    int reps;
    unsigned int base_seed;
    FILE *out;
    int i, rep;
    double b;
    double *sx1, *sx1_2, *sx2, *sx2_2, *sc, *sc_2;

    if(argc != 9)
    {
        usage(argv[0]);
        return 2;
    }

    outfile = argv[1];
    p12 = atof(argv[2]);
    x01 = atof(argv[3]);
    x02 = atof(argv[4]);
    bmin = atof(argv[5]);
    bmax = atof(argv[6]);
    reps = atoi(argv[7]);
    base_seed = (unsigned int)strtoul(argv[8], NULL, 10);

    if(reps < 1 || NDIV < 1 || bmax < bmin)
    {
        usage(argv[0]);
        return 2;
    }

    out = fopen(outfile, "w");
    if(out == NULL)
    {
        fprintf(stderr, "No se pudo abrir %s\n", outfile);
        return 1;
    }

    fprintf(out, "# N1 %d\n", N1);
    fprintf(out, "# N2 %d\n", N2);
    fprintf(out, "# T_MCS %d\n", T_MCS);
    fprintf(out, "# T_MAX %d\n", T_MAX);
    fprintf(out, "# W %d\n", W);
    fprintf(out, "# NDIV %d\n", NDIV);
    fprintf(out, "# P11 %.12g\n", (double)P11);
    fprintf(out, "# P12 %.12g\n", p12);
    fprintf(out, "# P22 %.12g\n", (double)P22);
    fprintf(out, "# k11 %.12g\n", (double)P11 * (N1 - 1.0));
    fprintf(out, "# k22 %.12g\n", (double)P22 * (N2 - 1.0));
    fprintf(out, "# R %.12g\n", (double)R);
    fprintf(out, "# E %.12g\n", (double)E);
    fprintf(out, "# UPDATE_RULE %d\n", UPDATE_RULE);
    fprintf(out, "# FERMI_BETA %.12g\n", (double)FERMI_BETA);
    fprintf(out, "# x01 %.12g\n", x01);
    fprintf(out, "# x02 %.12g\n", x02);
    fprintf(out, "# reps %d\n", reps);
    fprintf(out, "# seed %u\n", base_seed);
    fprintf(out, "# independence graph_per_b_rep\n");
    fprintf(out, "# b x1_mean x1_sem x2_mean x2_sem c_mean c_sem\n");

    if(NDIV == 1) delta = 0.0;
    else delta = (bmax - bmin) / (double)(NDIV - 1);

    sx1 = (double*)calloc(NDIV, sizeof(double));
    sx1_2 = (double*)calloc(NDIV, sizeof(double));
    sx2 = (double*)calloc(NDIV, sizeof(double));
    sx2_2 = (double*)calloc(NDIV, sizeof(double));
    sc = (double*)calloc(NDIV, sizeof(double));
    sc_2 = (double*)calloc(NDIV, sizeof(double));

    if(sx1 == NULL || sx1_2 == NULL || sx2 == NULL || sx2_2 == NULL ||
       sc == NULL || sc_2 == NULL)
    {
        fprintf(stderr, "No se pudo reservar memoria para acumuladores\n");
        fclose(out);
        free(sx1); free(sx1_2); free(sx2); free(sx2_2); free(sc); free(sc_2);
        return 1;
    }

    for(i = 0; i < NDIV; i++)
    {
        b = bmin + delta * (double)i;

        for(rep = 0; rep < reps; rep++)
        {
            Graph g;
            params lambda;
            u_min_max u;
            uint8_t gamma_new[NTOT], gamma_old[NTOT];
            double xc_1_med, xc_2_med, xc_1_sigma, xc_2_sigma;
            double c_med, c_sigma;
            unsigned int seed_graph, seed_state;

            seed_graph = base_seed
                         + (unsigned int)(1000003U * (unsigned int)(rep + 1))
                         + (unsigned int)(9176U * (unsigned int)(i + 1));
            seed_state = seed_graph ^ 0x9e3779b9U;

            lambda.b = b;
            lambda.e = E;
            lambda.r = R;
            u_bounds(lambda, &u);

            initial_ER(&g, P11, p12, P22, seed_graph);
            rng_seed(seed_state);
            ini_rand_Pr(gamma_old, x01, x02);

            time_loop(gamma_old, gamma_new, &g, lambda, u,
                      &xc_1_med, &xc_2_med, &xc_1_sigma, &xc_2_sigma,
                      &c_med, &c_sigma);

            accum(xc_1_med, sx1 + i, sx1_2 + i);
            accum(xc_2_med, sx2 + i, sx2_2 + i);
            accum(c_med, sc + i, sc_2 + i);

            free(g.col_idx);
        }

        printf("%d/%d b=%.6g p12=%.6g reps=%d\n", i + 1, NDIV, b, p12, reps);
        fflush(stdout);
    }

    for(i = 0; i < NDIV; i++)
    {
        double x1_mean, x1_sem, x2_mean, x2_sem, c_mean, c_sem;
        b = bmin + delta * (double)i;

        mean_sem(sx1[i], sx1_2[i], reps, &x1_mean, &x1_sem);
        mean_sem(sx2[i], sx2_2[i], reps, &x2_mean, &x2_sem);
        mean_sem(sc[i], sc_2[i], reps, &c_mean, &c_sem);

        fprintf(out, "%.12g\t%.12g\t%.12g\t%.12g\t%.12g\t%.12g\t%.12g\n",
                b, x1_mean, x1_sem, x2_mean, x2_sem, c_mean, c_sem);
    }

    free(sx1); free(sx1_2); free(sx2); free(sx2_2); free(sc); free(sc_2);
    fclose(out);
    return 0;
}
