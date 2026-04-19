/* File: sim.h
 * Purpose: Declara el bucle principal de simulacion y mediciones.
 */

#ifndef SIM_H
#define SIM_H

#include <stdint.h>
#include "types.h"

void time_loop(uint8_t *gamma, const Graph *g, params lambda, u_min_max u,double *xc_1, double *xc_2);
#endif
