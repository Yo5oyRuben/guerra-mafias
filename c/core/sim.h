/* File: sim.h
 * Purpose: Declara el bucle principal de simulacion y mediciones.
 */

#ifndef SIM_H
#define SIM_H

#include <stdint.h>
#include "types.h"

#if SAVE_SERIES
void time_loop(uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g, params lambda, u_min_max u,
               double *xc_1, double *xc_2, int *N_control,
               double *xc_1_med, double *xc_2_med,
               double *xc_1_sigma, double *xc_2_sigma);
#else
void time_loop(uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g, params lambda, u_min_max u,
               double *xc_1_med, double *xc_2_med, double *xc_1_sigma,
               double *xc_2_sigma, double *c_med, double *c_sigma);
#endif
#endif
