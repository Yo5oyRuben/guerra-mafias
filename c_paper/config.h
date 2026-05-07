#ifndef CONFIG_H
#define CONFIG_H

#ifndef N1
#define N1 400
#endif
#ifndef N2
#define N2 1200
#endif
#define NTOT (N1 + N2)

#ifndef T_MCS
#define T_MCS 1000
#endif
#ifndef T_MAX
#define T_MAX 25000
#endif
#ifndef W
#define W 2000
#endif
#ifndef NDIV
#define NDIV 100
#endif

/* Parametros ER por bloques */
#ifndef P11
#define P11 0.9
#endif
#ifndef P12
#define P12 0.02
#endif
#ifndef P22
#define P22 0.9
#endif

/*parametros de lambda*/
#ifndef R
#define R 0
#endif
#ifndef E
#define E -0.4
#endif
#ifndef B
#define B 1.06
#endif
#ifndef BMIN
#define BMIN 1
#endif
#ifndef BMAX
#define BMAX 3
#endif

/*parametros para el limite de alta conectividad*/
#ifndef N_INI_NDIV
#define N_INI_NDIV 8
#endif
#ifndef N_INI_COND
#define N_INI_COND 3
#endif

/*para debug*/
#ifndef SAVE_SERIES
#define SAVE_SERIES 0
#endif


#endif











