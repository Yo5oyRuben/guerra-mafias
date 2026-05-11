#include "../../head.h"
#include "scan_initial_plane.h"

/*esta funcion ejecuta un punto inicial en la rejilla.
es decir, dadas las coordenadas del punto en la rejilla, genera un estado inicial 
aleatorio con esa fraccion de nodos en cada estado, y mira a ver donde acaba asintoticamente*/
void run_initial_point(const Graph *g, params lambda, u_min_max u,
                       point2d x0, int ix, int iy, int n_reps, FILE *out)
{
    int i, t_relax;
    double x1_0,x2_0, xc_1_med,xc_2_med,xc_1_sigma,xc_2_sigma,c_med,c_sigma;
    uint8_t gamma_new[NTOT], gamma_old[NTOT];

    for(i=0;i<n_reps;i++)
    {
        ini_rand_x0(gamma_old,x0.x1,x0.x2);
        x1_0=xc1(gamma_old);
        x2_0=xc2(gamma_old);
        t_relax=time_loop_relax(gamma_old,gamma_new,g,lambda,u,&xc_1_med,&xc_2_med,
            &xc_1_sigma,&xc_2_sigma,&c_med,&c_sigma);
        
        /*ix,iy,x1_0,x2_0,rep,x1_inf,x2_inf,sigma_1,sigma_2,t_relax*/
        fprintf(out,"%d\t%d\t%.12f\t%.12f\t%d\t%.12f\t%.12f\t%.12f\t%.12f\t%d\n",
            ix,iy,x1_0,x2_0,i+1,xc_1_med,xc_2_med,xc_1_sigma,xc_2_sigma,t_relax);
    }
}

/*a esta funcion se le pasa un rango de indices x para escanear. se hace asi porque 
luego la funcion principal puede llamarla con diferentes rangos. asi podemos lanzar 
cosas en paralelo para que la simulaicon vaya mas rapido (son muy largas).*/
void scan_initial_plane_range(const Graph *g, params lambda, u_min_max u,
                              int ndiv, int n_reps, int ix_min, int ix_max,
                              const char *filename)
{
    int i,j;
    point2d x0;
    FILE *out;

    if(ix_min<0) ix_min=0;
    if(ix_max>ndiv) ix_max=ndiv;
    if(ix_min>ix_max) return;

    /*abrimos el fichero de salida. esta funcion se desarrolla mas abajo*/
    out=open_initial_plane_file(filename,lambda,P12,ndiv,n_reps);
    if(out==NULL)
    {
        printf("No se pudo abrir el fichero %s\t:(\n",filename);
        return;
    }

    /*barremos el rango de valores que nos interesa*/
    for(i=ix_min;i<=ix_max;i++)
    {
        for(j=0;j<=ndiv;j++)
        {
            x0=grid_point(i,j,ndiv);
            run_initial_point(g,lambda,u,x0,i,j,n_reps,out);
        }
    }
    fclose(out);
}

/*esta funcion es solo un envoltorio que escanea todo el plano inicial de golpe*/
void scan_initial_plane(const Graph *g, params lambda, u_min_max u,int ndiv,int n_reps, const char *filename)
{
    scan_initial_plane_range(g,lambda,u,ndiv,n_reps,0,ndiv,filename);
}

/*esta funcion abre el archivo para escribir los resultados del escaneo del plano inicial*/
FILE *open_initial_plane_file(const char *filename, params lambda, double p12,
                              int ndiv, int n_reps)
{
    FILE *out;
    double A_prima,B_prima,E_0,E_1;
    double rho,a12,a21,d,h,den;
    out=fopen(filename,"w");
    if(out==NULL)
    {
        printf("No se pudo abrir %s\t:(\n", filename);
        return NULL;
    }

    /*aqui tomamos las expresiones analiticas de los puntos fijos del paper y las
    calculamos a lo bruto para los parametros que se le pasan a la funcion*/
    rho=(double)N1/N2;
    a12=p12/rho;
    a21=p12*rho;
    d=lambda.b-1-lambda.r;
    h=lambda.b-1-lambda.e;
    den=p12*p12*h*h-d*d;

    A_prima=-(lambda.r+a21*lambda.e)/d;
    B_prima=-(lambda.r+a12*lambda.e)/d;
    E_0=(d*(lambda.r+a12*lambda.e)-a12*h*(lambda.r+a21*lambda.e))/den;
    E_1=(d*(lambda.r+a21*lambda.e)-a21*h*(lambda.r+a12*lambda.e))/den;

    /*se escribe la cabecera del archivo con todo detalle*/
    fprintf(out,"# scan initial plane\n");
    fprintf(out,"# b %.12g\n", lambda.b);
    fprintf(out,"# r %.12g\n", lambda.r);
    fprintf(out,"# e %.12g\n", lambda.e);
    fprintf(out,"# N1 %d\n", N1);
    fprintf(out,"# N2 %d\n", N2);
    fprintf(out,"# P11 %.12g\n", (double)P11);
    fprintf(out,"# p12 %.12g\n", p12);
    fprintf(out,"# P22 %.12g\n", (double)P22);
    fprintf(out,"# T_MCS %d\n", T_MCS);
    fprintf(out,"# T_MAX %d\n", T_MAX);
    fprintf(out,"# W %d\n", W);
    fprintf(out,"# UPDATE_RULE %d\n", UPDATE_RULE);
    fprintf(out,"# FERMI_BETA %.12g\n", (double)FERMI_BETA);
    fprintf(out,"# DEGREE_ALPHA %.12g\n", (double)DEGREE_ALPHA);
    fprintf(out,"# DEGREE_FACTOR_MIN %.12g\n", (double)DEGREE_FACTOR_MIN);
    fprintf(out,"# DEGREE_FACTOR_MAX %.12g\n", (double)DEGREE_FACTOR_MAX);
    fprintf(out,"# ndiv %d\n", ndiv);
    fprintf(out,"# n_reps %d\n", n_reps);
    fprintf(out, "# A:(0,1),\tA':(0,%.3f),\tB:(1,0),\tB'=(%.3f,0),\tC:(1,1),\tD:(0,0),\tE:(%.3f,%.3f) \n",
    A_prima,B_prima,E_0,E_1);
    fprintf(out,"# columns: ix iy x1_0 x2_0 rep x1_inf x2_inf sigma_1 sigma_2 t_relax\n");

    return out;
}
