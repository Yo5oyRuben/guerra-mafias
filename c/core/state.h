/* File: state.h
 * Purpose: Declara funciones para inicializar y actualizar el microestado (sigmas por nodo).
 */

#ifndef STATE_H
#define STATE_H

#include <stdint.h>

void ini_rand_x0(uint8_t *gamma, double x01, double x02);
void ini_rand_Pr(uint8_t *gamma, double p1, double p2);
void ini_C(uint8_t *gamma);
void ini_D(uint8_t *gamma);

double xc1(const uint8_t *gamma);
double xc2(const uint8_t *gamma);

#endif
