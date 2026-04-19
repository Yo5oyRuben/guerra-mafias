/* File: run_network.c
 * Purpose: Punto de entrada ejecutable para correr el caso con red.
 */

#include "head.h"

int main(void) {
    unsigned int seed_graph;
    Graph g;

    seed_graph = (unsigned int)time(NULL);
    g.col_idx = NULL;

    /* Ejemplo: construye red por bloques ER */
    initial_ER(&g, 0.2, 0.05, 0.2, seed_graph);

    printf("[C] Network ready. m=%d\n", g.m);

    if (g.col_idx != NULL) {
        free(g.col_idx);
        g.col_idx = NULL;
    }

    return 0;
}
