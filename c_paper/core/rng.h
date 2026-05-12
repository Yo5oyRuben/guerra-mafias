#ifndef RNG_H
#define RNG_H

void rng_seed(unsigned int seed);
unsigned int rng_u32(void);
double fran(void);
int rng_int(int n);

/*las funciones de las que disponemos son: 
- rng_seed que inicializa el generador
- rng_u32 que genera un numero entero aleatorio
- fran que genera un numero real aleatorio entre 0 y 1
- rng_int que genera un numero entero aleatorio en un rango
*/

#endif
