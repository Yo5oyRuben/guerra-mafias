/* File: payoff.h
 * Purpose: Declara el calculo de pagos/fitness de nodos y poblaciones.
 */

#ifndef PAYOFF_H
#define PAYOFF_H

#include <stdint.h>
#include "types.h"

double u_intra(uint8_t si, uint8_t sj, params lambda);
double u_inter(uint8_t si, uint8_t sj, params lambda);

double Pi_i(int i, const uint8_t *gamma, params lambda, const Graph *g);
double delta_ij(int i, int j, const uint8_t *gamma, params lambda, const Graph *g);

#endif
