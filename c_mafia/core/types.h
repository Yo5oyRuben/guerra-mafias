/* File: types.h
 * Purpose: Define tipos y estructuras de datos compartidas (por ejemplo, representacion de redes y parametros).
 */

#ifndef TYPES_H
#define TYPES_H

#include "../config.h"

typedef struct
{
    int m;
    int row_ptr[NTOT + 1];
    int *col_idx;          /* size m */
    int k_intra[NTOT];
    int k_inter[NTOT];
    double R;
    double max_k_intra1;
    double max_k_intra2;
} Graph;
#endif
