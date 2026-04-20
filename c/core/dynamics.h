/* File: dynamics.h
 * Purpose: Declara reglas de actualizacion estocastica y pasos Monte Carlo.
 */

#ifndef DYNAMICS_H
#define DYNAMICS_H

#include <stdint.h>
#include "types.h"

void u_bounds(params lambda, u_min_max *u);
double Pij(int i, int j, const Graph *g, params lambda, u_min_max u, const uint8_t *gamma);
void time_step(const uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g, params lambda, u_min_max u);

#endif
