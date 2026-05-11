#include "../../head.h"
#include "sweeps.h"

/*este main hace un barrido sobre p12 y sobre b para recrear las figuras 3 y 4 del paper.
esta version es más de prueba, para hacer graficas rápidas. la version potente
se encuentra en el otro archivo*/
int main(void)
{
    int i;
    double c_med[NDIV],c_sigma[NDIV],b_values[NDIV];
    double p12[7]={0.0,0.001,0.002,0.005,0.01,0.02,0.04};

    char filename[256];
    FILE *out;

    /*metemos en el nombre del archivo informacion de la simulacion*/
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
    out=fopen(filename,"w");
    if(out==NULL)
    {
        printf("No se pudo abrir %s\n", filename);
        return 1;
    }
    fclose(out);

    /*para cada valor de p12, hacemos el barrido sobre b y guardamos los resultados*/
    for(i=0;i<7;i++)
    {
        sweep_b(p12[i],c_med,c_sigma,b_values);
        print_c_p12(c_med,c_sigma,b_values,p12[i],filename);
        printf("%d/7\n",i+1);
    }
    return 0;
}
