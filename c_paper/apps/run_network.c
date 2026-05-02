/* File: run_network.c
 * Purpose: Punto de entrada ejecutable para correr el caso con red.
 */

#include "../head.h"
#include "sweeps.h"

int main(void)
{
    int i;
    double c_med[NDIV],c_sigma[NDIV],b_values[NDIV];
    double p12[7]={0.0,0.001,0.002,0.005,0.01,0.02,0.04};

    char filename[256];
    snprintf(
        filename,
        sizeof(filename),
        "c_paper/out/raw/sweep_b/sweep_b_E_%g_R_%g_k11_%g_k22_%g_N_%d.txt",
        (double)E,
        (double)R,
        P11*(N1 - 1.0),
        P22*(N2 - 1.0),
        NTOT
    );
    FILE *out=fopen(filename,"w");
    if(out==NULL)
    {
        printf("No se pudo abrir %s\n", filename);
        return 1;
    }
    fclose(out);


    for(i=0;i<7;i++)
    {
        sweep_b(p12[i],c_med,c_sigma,b_values);
        print_c_p12(c_med,c_sigma,b_values,p12[i],filename);
        printf("%d/7\n",i+1);
    }
    return 0;
}
