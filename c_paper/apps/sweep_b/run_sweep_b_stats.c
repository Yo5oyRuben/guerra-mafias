#include "../../head.h"
#include <math.h>
#include <string.h>

/*esta funcion muestra el uso correcto del programa*/
static void usage(const char *prog)
{
    fprintf(stderr,
            "Uso: %s OUTFILE P12 X01 X02 BMIN BMAX REPS SEED\n"
            "Escribe columnas: b x1_mean x1_sem x2_mean x2_sem c_mean c_sem\n",
            prog);
}

/*esta funcion escribe el encabezado del archivo de salida*/
static void write_header(FILE *out, double p12, double x01, double x02,
                         int reps, unsigned int base_seed)
{
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
    fprintf(out, "# DEGREE_ALPHA %.12g\n", (double)DEGREE_ALPHA);
    fprintf(out, "# DEGREE_FACTOR_MIN %.12g\n", (double)DEGREE_FACTOR_MIN);
    fprintf(out, "# DEGREE_FACTOR_MAX %.12g\n", (double)DEGREE_FACTOR_MAX);
    fprintf(out, "# x01 %.12g\n", x01);
    fprintf(out, "# x02 %.12g\n", x02);
    fprintf(out, "# reps %d\n", reps);
    fprintf(out, "# seed %u\n", base_seed);
    fprintf(out, "# independence graph_per_b_rep\n");
    fprintf(out, "# b x1_mean x1_sem x2_mean x2_sem c_mean c_sem\n");
}

/*esta funcion hace un barrido sobre b desde BMIN hasta BMAX, con NDIV puntos, para un valor dado de p12.
a diferencia del otro barrido de b, este hace muchas replicas para cada valor de b,
y guarda la media y el error de x1,x2,c para cada b. genera ademas una red independiente por replica.

se pasan por consola una serie de argumentos.
- argc es el numero de argumentos de la funcion main
- argv es un array de punteros a strings que contiene los argumentos.
en concreto, los argumentos son:
  argv[0] = nombre del ejecutable
  argv[1] = OUTFILE, fichero de salida
  argv[2] = P12, probabilidad de enlace entre redes
  argv[3] = X01, fraccion inicial de cooperadores en la poblacion 1
  argv[4] = X02, fraccion inicial de cooperadores en la poblacion 2
  argv[5] = BMIN, primer valor de b
  argv[6] = BMAX, ultimo valor de b
  argv[7] = REPS, numero de replicas por cada valor de b
  argv[8] = SEED, semilla base para redes y estados iniciales
*/
int main(int argc, char **argv)
{

    const char *outfile;
    double p12, x01, x02, bmin, bmax, delta;
    int reps;
    unsigned int base_seed;
    FILE *out;
    int i, rep;
    double b;
    Graph g;
    params lambda;
    u_min_max u;
    uint8_t gamma_new[NTOT], gamma_old[NTOT];
    double xc_1_med, xc_2_med, xc_1_sigma, xc_2_sigma;
    double c_med, c_sigma;
    unsigned int seed_graph, seed_state;
    double x1_mean_values[NDIV], x1_sem_values[NDIV];
    double x2_mean_values[NDIV], x2_sem_values[NDIV];
    double c_mean_values[NDIV], c_sem_values[NDIV];
    double *x1_reps, *x2_reps, *c_reps;

    /*el programa espera 9 argumentos*/
    if(argc!=9)
    {
        usage(argv[0]);
        return 2;
    }

    /*leemos los argumentos*/
    outfile = argv[1];
    /*atof es una funcion que convierte una cadena en un numero de punto flotante*/
    p12 = atof(argv[2]);
    x01 = atof(argv[3]);
    x02 = atof(argv[4]);
    bmin = atof(argv[5]);
    bmax = atof(argv[6]);
    reps = atoi(argv[7]);
    /*strtoul es una funcion que convierte una cadena en un numero entero sin signo*/
    base_seed = (unsigned int)strtoul(argv[8], NULL, 10);

    /*control por si los parámetros no tienen sentido*/
    if(reps<1||NDIV<1||bmax<bmin)
    {
        usage(argv[0]);
        return 2;
    }

    out=fopen(outfile,"w");
    if(out==NULL)
        return 1;

    write_header(out, p12, x01, x02, reps, base_seed);

    if(NDIV==1) delta=0.0;
    else delta=(bmax-bmin)/(double)(NDIV-1);

    /*puesto que reps se da en tiempo de ejecucion, necesitamos reservar memoria dinamicamente*/
    x1_reps=(double*)malloc(reps*sizeof(double));
    x2_reps=(double*)malloc(reps*sizeof(double));
    c_reps=(double*)malloc(reps*sizeof(double));

    /*errores*/
    if(x1_reps==NULL||x2_reps==NULL||c_reps==NULL)
    {
        fprintf(stderr, "No se pudo reservar memoria para estadistica\n");
        fclose(out);
        free(x1_reps); free(x2_reps); free(c_reps);
        return 1;
    }

    lambda.e=E;
    lambda.r=R;
    /*bucle principal para cada valor de b*/
    for(i=0;i<NDIV;i++)
    {
        lambda.b=bmin+delta*(double)i;
        /*para cada b, realizamos reps replicas*/
        for(rep=0;rep<reps;rep++)
        {
            /*usamos como semilla base la semilla proporcionada, más un offset para cada replica y cada valor de b*/
            seed_graph=base_seed
                         + (unsigned int)(1000003U * (unsigned int)(rep + 1))
                         + (unsigned int)(9176U * (unsigned int)(i + 1));
            seed_state=seed_graph^0x9e3779b9U;
            
            /*inicializamos la red y los estados iniciales*/
            u_bounds(lambda, &u);
            initial_ER(&g, P11, p12, P22, seed_graph);
            rng_seed(seed_state);
            ini_rand_Pr(gamma_old, x01, x02);

            /*bucle de tiempo para medir el estado final*/
            time_loop(gamma_old, gamma_new, &g, lambda, u,
                      &xc_1_med, &xc_2_med, &xc_1_sigma, &xc_2_sigma,
                      &c_med, &c_sigma);
            /*guardamos el estado final*/
            x1_reps[rep]=xc_1_med;
            x2_reps[rep]=xc_2_med;
            c_reps[rep]=c_med;
            free(g.col_idx);
        }

        /*una vez hemos medido todas las replicas, calculamos medias y varianzas*/
        if(reps > 1)
        {
            medvar(x1_reps,reps,x1_mean_values+i,x1_sem_values+i);
            medvar(x2_reps,reps,x2_mean_values+i,x2_sem_values+i);
            medvar(c_reps,reps,c_mean_values+i,c_sem_values+i);
            /*normalizamos con la raiz para tener errores del estimador de la media*/
            x1_sem_values[i]/=sqrt((double)reps);
            x2_sem_values[i]/=sqrt((double)reps);
            c_sem_values[i]/=sqrt((double)reps);
        }
        else
        {
            x1_mean_values[i]=x1_reps[0];
            x2_mean_values[i]=x2_reps[0];
            c_mean_values[i]=c_reps[0];
            x1_sem_values[i]=0.0;
            x2_sem_values[i]=0.0;
            c_sem_values[i]=0.0;
        }

        /*ver el progreso en tiempo real*/
        printf("%d/%d b=%.6g p12=%.6g reps=%d\n", i + 1, NDIV, lambda.b, p12, reps);
        fflush(stdout);
    }

    /*escribimos los resultados*/
    for(i=0;i<NDIV;i++)
    {
        lambda.b=bmin+delta*(double)i;

        fprintf(out, "%.12g\t%.12g\t%.12g\t%.12g\t%.12g\t%.12g\t%.12g\n",
                lambda.b,
                x1_mean_values[i], x1_sem_values[i],
                x2_mean_values[i], x2_sem_values[i],
                c_mean_values[i], c_sem_values[i]);
    }

    free(x1_reps); free(x2_reps); free(c_reps);
    fclose(out);
    return 0;
}
