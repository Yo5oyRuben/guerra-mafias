/* File: types.h
 * Purpose: Define tipos y estructuras de datos compartidas (por ejemplo, representacion de redes y parametros).
 */

#ifndef TYPES_H
#define TYPES_H

#include "config.h"

typedef struct
{
    int m;
    int row_ptr[NTOT + 1];
    int *col_idx;          /* size m */
    int k_intra[NTOT];
    int k_inter[NTOT];
} Graph;

typedef struct
{
    double b;
    double r;
    double e;
} params;

typedef struct
{
    double u_inter_min;
    double u_inter_max;
    double u_intra_min;
    double u_intra_max;
} u_min_max;
#endif
