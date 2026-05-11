#ifndef UTILS_H
#define UTILS_H

#include "types.h"

void medvar(const double *v, int n, double *med, double *sigma);
point2d grid_point(int ix, int iy, int ndiv);
#endif
