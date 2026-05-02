#include "../../head.h"
#include "scan_initial_plane.h"

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

void scan_initial_plane(const Graph *g, params lambda, u_min_max u,int ndiv,int n_reps, const char *filename)
{
    scan_initial_plane_range(g,lambda,u,ndiv,n_reps,0,ndiv,filename);
}

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

    out=open_initial_plane_file(filename,lambda,P12,ndiv,n_reps);
    if(out==NULL)
    {
        printf("No se pudo abrir el fichero %s\t:(\n",filename);
        return;
    }

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

FILE *open_initial_plane_file(const char *filename, params lambda, double p12,
                              int ndiv, int n_reps)
{
    FILE *out;
    double A_prima, B_prima, E_0, E_1;
    out=fopen(filename,"w");
    if(out==NULL)
    {
        printf("No se pudo abrir %s\t:(\n", filename);
        return NULL;
    }

    A_prima=-(lambda.r+(double)N1/N2*p12*lambda.e)/(lambda.b-1-lambda.r);
    B_prima=A_prima*(double)N1/N2;
    E_0=((lambda.b-1-lambda.r)*((double)N1/N2*lambda.r+p12*lambda.e)
        -p12*(lambda.b-1-lambda.e)*(lambda.r+(double)N1/N2*p12*lambda.e))/
        ((double)N1/N2*(p12*p12*(lambda.b-1-lambda.e)*(lambda.b-1-lambda.e)-(lambda.b-1-lambda.r)*(lambda.b-1-lambda.r)));
    E_1=E_0*(double)N1/N2;

    fprintf(out,"# scan initial plane\n");
    fprintf(out,"# b %.12g\n", lambda.b);
    fprintf(out,"# r %.12g\n", lambda.r);
    fprintf(out,"# e %.12g\n", lambda.e);
    fprintf(out,"# p12 %.12g\n", p12);
    fprintf(out,"# ndiv %d\n", ndiv);
    fprintf(out,"# n_reps %d\n", n_reps);
    fprintf(out, "# A:(0,1),\tA':(0,%.3f),\tB:(1,0),\tB'=(%.3f,0),\tC:(1,1),\tD:(0,0),\tE:(%.3f,%.3f) \n",
    A_prima,B_prima,E_0,E_1);
    fprintf(out,"# columns: ix iy x1_0 x2_0 rep x1_inf x2_inf sigma_1 sigma_2 t_relax\n");

    return out;
}
