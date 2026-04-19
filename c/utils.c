/* File: utils.c
 * Purpose: Implementa utilidades numericas generales.
 */

#include <math.h>
#include "utils.h"

void medvar(const double *v, int n, double *med, double *sigma)
{
    int i;
    double sum,var;
    *med=0;
    *sigma=0;
    sum=var=0;
    
    for(i=0;i<n;i++) sum += v[i];
    *med=sum/(double)n;

    for (i=0;i<n;i++) var+=(v[i]-sum)*(v[i]-sum);
    var/=(double)(n-1);
    *sigma = sqrt(var);
}
