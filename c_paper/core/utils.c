#include <math.h>
#include "utils.h"
#include "types.h"

/*calcula media y varianza de un array*/
void medvar(const double *v, int n, double *med, double *sigma)
{
    int i;
    double sum,var;
    *med=0;
    *sigma=0;
    sum=var=0;
    
    for(i=0;i<n;i++) sum += v[i];
    *med=sum/(double)n;

    for (i=0;i<n;i++) var+=(v[i]-*med)*(v[i]-*med);
    var/=(double)(n-1);
    *sigma = sqrt(var);
}

/*da las coordenadas de un punto en la rejilla en funcion de sus indices*/
point2d grid_point(int ix, int iy, int ndiv)
{
    point2d point;
    point.x1=ix/(double)ndiv;
    point.x2=iy/(double)ndiv;
    return point;
}
