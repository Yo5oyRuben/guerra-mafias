/* File: io.c
 * Purpose: Implementa escritura/lectura de datos (por ejemplo CSV) de simulacion.
 */

#include <stdio.h>

int io_write_x_series(const char *path, const double *x1, const double *x2, int n)
{
    int t;
    FILE *fp=fopen(path,"w");
    if(fp==NULL) return 1;

    fprintf(fp,"# t x1 x2\n");
    for(t=0;t<n;t++)
    {
        fprintf(fp,"%d %.10f %.10f\n",t,x1[t],x2[t]);
    }

    fclose(fp);
    return 0;
}
