#ifndef CONFIG_H
#define CONFIG_H

#define N1 100
#define N2 100
#define NTOT (N1 + N2)

#define T_MCS 1000
#define T_MAX 50000
#define W 2000
#define NDIV 100

/* Parametros ER por bloques */
#define P11 0.9 /*(6.0/(N1-1.0))*/
#define P12 0.3
#define P22 0.9 /*(6.0/(N2-1.0))*/

/*parametros de lambda*/
#define R 0
#define E -0.4
#define B 1.2
#define BMIN 1
#define BMAX 3

/*parametros para el limite de alta conectividad*/
#define N_INI_NDIV 10
#define N_INI_COND 5

/*para debug*/
#define SAVE_SERIES 0


#endif
