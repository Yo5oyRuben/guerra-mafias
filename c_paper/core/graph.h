#ifndef GRAPH_H
#define GRAPH_H

#include "types.h"

/*Inicializa el grafo con ER por bloques (W11, W22, W12/W21)*/
void initial_ER(Graph *g, double p11, double p12, double p22, unsigned int seed);
void split_degrees_i(Graph *g, int i);

#endif
