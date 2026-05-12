#include "../../head.h"
#include "scan_initial_plane.h"

/*esta funcion ejecuta el escaneo del plano inicial. lo hace en paralelo.
los argumentos de la funcion main permiten controlar los parametros del escaneo:
- argc es el numero de argumentos de la funcion main
- argv es un array de punteros a strings que contiene los argumentos
en concreto, se pueden pasar 3 o 5 argumentos:
- argv[1] es el indice minimo de x0 a escanear (en el eje x)
- argv[2] es el indice maximo de x0 a escanear (en el eje x)
- argv[3] es el nombre del archivo de salida(contendrá informacion sobre los parametros de la simulaicon)
- argv[4] es el numero de divisiones del plano inicial (ndiv)
- argv[5] es el numero de repeticiones para cada punto del plano inicial (n_reps)
*/
int main(int argc, char **argv)
{
    Graph g;
    params lambda;
    u_min_max u;
    int ndiv,n_reps,i_min,i_max;
    double p12;
    const char *filename;

    ndiv=N_INI_NDIV;
    n_reps=N_INI_COND;
    i_min=0;
    i_max=ndiv;
    p12=P12;
    filename="c_paper/out/raw/initial_plane/initial_plane_test.txt";

    /*si se le pasan argumentos, entonces el barrido se hace según los valores proporcionados*/
    if(argc==4||argc==6)
    {
        /*atoi es una funcion de C que convierte una string en un entero*/
        i_min=atoi(argv[1]);
        i_max=atoi(argv[2]);
        filename=argv[3];
        if(argc==6)
        {
            ndiv=atoi(argv[4]);
            n_reps=atoi(argv[5]);
        }
    }

    /*se asigna valores e inicializan cosas en funcion de los parámetros del archivo
    de configuracion*/
    lambda.b=B;
    lambda.r=R;
    lambda.e=E;
    u_bounds(lambda,&u);
    initial_ER(&g,P11,p12,P22,(unsigned int)time(NULL));

    /*se llama a la funcion de escaneo*/
    scan_initial_plane_range(&g, lambda, u, ndiv, n_reps, i_min, i_max, filename);
    free(g.col_idx);
    return 0;
}
