/* File: run_well_mixed.c
 * Purpose: Punto de entrada ejecutable para correr el caso well-mixed.
 */

#include "../../head.h"
#include "sweeps.h"

int main(void)
{
    int i;
    double c_med[NDIV],c_sigma[NDIV],b_values[NDIV];
    double p12[7]={0.0,0.001,0.002,0.005,0.01,0.02,0.04};
    char *filename="c/out/sweep_b_p12.txt";
    FILE *out=fopen(filename,"w");
    fclose(out);

    for(i=0;i<7;i++)
    {
        sweep_b(p12[i],c_med,c_sigma,b_values);
        print_c_p12(c_med,c_sigma,b_values,p12[i],filename);
        printf("%d/7\n",i+1);
    }

    return 0;
}
