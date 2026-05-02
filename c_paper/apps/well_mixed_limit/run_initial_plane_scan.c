#include "../../head.h"
#include "scan_initial_plane.h"

int main(int argc, char **argv)
{
    Graph g;
    params lambda;
    u_min_max u;

    int ndiv;
    int n_reps;
    int ix_min;
    int ix_max;
    double p12;
    const char *filename;

    ndiv=N_INI_NDIV;
    n_reps=N_INI_COND;
    ix_min=0;
    ix_max=ndiv;
    p12=P12;

    filename="c_paper/out/raw/initial_plane/initial_plane_test.txt";

    if(argc==4 || argc==6)
    {
        ix_min=atoi(argv[1]);
        ix_max=atoi(argv[2]);
        filename=argv[3];
        if(argc==6)
        {
            ndiv=atoi(argv[4]);
            n_reps=atoi(argv[5]);
        }
    }

    lambda.b=B;
    lambda.r=R;
    lambda.e=E;

    u_bounds(lambda,&u);

    initial_ER(&g,P11,p12,P22,12345U);

    scan_initial_plane_range(&g, lambda, u, ndiv, n_reps, ix_min, ix_max, filename);
    free(g.col_idx);
    return 0;
}
