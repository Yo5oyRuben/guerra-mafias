/* File: rng.c
 * Purpose: Implementa el generador de numeros aleatorios y utilidades de muestreo.
 */

#include "rng.h"

/*
 * Generador Parisi-Rapuano
 */

#define PR_STATE_SIZE 256U
#define PR_MASK 255U
#define PR_A 24U
#define PR_B 55U
#define PR_C 61U

static unsigned int pr_state[PR_STATE_SIZE];
static unsigned int pr_idx = 0U;
static int pr_seeded = 0;

/* Mezclador simple para expandir semilla a 32 bits con buena dispersion. */
static unsigned int splitmix32_step(unsigned int *x) {
    unsigned int z;
    *x += 0x9E3779B9U;
    z = *x;
    z ^= z >> 16;
    z *= 0x85EBCA6BU;
    z ^= z >> 13;
    z *= 0xC2B2AE35U;
    z ^= z >> 16;
    return z;
}

void rng_seed(unsigned int seed) {
    unsigned int i;
    unsigned int x;

    if (seed == 0U) {
        seed = 0xA341316CU; /* evita semilla nula */
    }

    x = seed;
    for (i = 0U; i < PR_STATE_SIZE; ++i) {
        pr_state[i] = splitmix32_step(&x);
    }

    /* Warm-up para desacoplar del estado inicial. */
    pr_idx = 0U;
    for (i = 0U; i < (PR_STATE_SIZE * 4U); ++i) {
        (void)rng_u32();
    }

    pr_seeded = 1;
}

unsigned int rng_u32(void) {
    unsigned int ia;
    unsigned int ib;
    unsigned int ic;
    unsigned int y;
    unsigned int out;

    if (!pr_seeded) {
        rng_seed(0x12345678U);
    }

    pr_idx = (pr_idx + 1U) & PR_MASK;

    ia = (pr_idx - PR_A) & PR_MASK;
    ib = (pr_idx - PR_B) & PR_MASK;
    ic = (pr_idx - PR_C) & PR_MASK;

    y = pr_state[ia] + pr_state[ib];
    out = y ^ pr_state[ic];
    pr_state[pr_idx] = out;

    return out;
}

double fran(void) {
    /* 2^-32 = 1 / 4294967296 */
    return ((double)rng_u32()) * (1.0 / 4294967296.0);
}

int rng_int(int n) {
    unsigned int limit;
    unsigned int r;

    if (n <= 0) {
        return 0;
    }

    /* Rejection sampling para evitar sesgo modulo. */
    limit = 0xFFFFFFFFU - (0xFFFFFFFFU % (unsigned int)n);
    do {
        r = rng_u32();
    } while (r >= limit);

    return (int)(r % (unsigned int)n);
}
