/* File: payoff.h
 * Purpose: Declara el calculo de pagos/fitness de nodos y poblaciones.
 */

#ifndef PAYOFF_H
#define PAYOFF_H

#include <stdint.h>
#include "types.h"

double u_intra(uint8_t si, uint8_t sj, double qi, double qj);

double Pi_i(int i, const uint8_t *gamma, const Graph *g);
double delta_ij(int i, int j, const uint8_t *gamma, const Graph *g);
#endif
