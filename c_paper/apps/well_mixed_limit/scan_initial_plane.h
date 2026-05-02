#ifndef SCAN_INITIAL_PLANE_H
#define SCAN_INITIAL_PLANE_H

#include <stdio.h>
#include "../../core/types.h"

void run_initial_point(const Graph *g, params lambda, u_min_max u,
                       point2d x0, int ix, int iy, int n_reps, FILE *out);

void scan_initial_plane(const Graph *g, params lambda, u_min_max u,
                        int ndiv, int n_reps, const char *filename);

void scan_initial_plane_range(const Graph *g, params lambda, u_min_max u,
                              int ndiv, int n_reps, int ix_min, int ix_max,
                              const char *filename);

FILE *open_initial_plane_file(const char *filename, params lambda, double p12,
                              int ndiv, int n_reps);

#endif
