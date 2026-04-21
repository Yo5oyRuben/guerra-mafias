/* File: rng.h
 * Purpose: Declara la interfaz del generador de numeros aleatorios usado por las simulaciones.
 */

#ifndef RNG_H
#define RNG_H

void rng_seed(unsigned int seed);
unsigned int rng_u32(void);
double fran(void);
int rng_int(int n);

#endif
