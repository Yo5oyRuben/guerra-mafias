#ifndef TYPES_H
#define TYPES_H

#include "../config.h"

/*struct para almacenar toda la informacion de la red no dirigida y no pesada. 
para ahorrar espacio en memoria, no guardamos toda la matriz. sabemos que los unicos
valores que puede tomar cada entrada son 0 o 1. en el grafo se guarda:
- el numero total de aristas m
- un vector de enteros de tamaño NTOT + 1: row_ptr.
  este vector almacena en su componente i el indice donde empiezan los vecinos del nodo i.
- un vector de enteros de tamaño m: col_idx.
  este vector almacena en su componente j el grado de el nodo j+1 menos el grado del j.
de este modo, para el nodo i, sus vecinos estan en col_idx desde el indice row_ptr[i] hasta el indice row_ptr[i+1]-1.
  */
typedef struct
{
    int m;
    int row_ptr[NTOT + 1];
    int *col_idx;          /* size m */

    /*pese a que la informacion completa del grafo está en row_ptr y col_idx, por comodidad 
    y porque es más optimo en uno de los bucles centrales del código, si se elige la opcion
    de probabilidad de copia lineal en grado, guardamos los grados intra y inter*/
    int k_intra[NTOT];
    int k_inter[NTOT];
} Graph;

/*vector de parámetros de las matrices de pago*/
typedef struct
{
    double b;
    double r;
    double e;
} params;

/*cotas de los pagos*/
typedef struct
{
    double u_inter_min;
    double u_inter_max;
    double u_intra_min;
    double u_intra_max;
} u_min_max;

typedef struct
{
    double x1;
    double x2;
} point2d;
#endif
