#ifndef CONFIG_H
#define CONFIG_H

#define N1 1000
#define N2 1000
#define NTOT (N1 + N2)

#define T_MCS 100
#define T_MAX 2000
#define W 200
#define NDIV 50

/* Parametros ER por bloques */
#define P11 (6.0/(N1-1.0))
#define P12 0.0
#define P22 (6.0/(N2-1.0))

/*parametros de lambda*/
#define R 0
#define E -0.4
#define B 2
#define BMIN 1
#define BMAX 3

/*para debug*/
#define SAVE_SERIES 0


#endif
