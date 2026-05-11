#include <math.h>
#include "../config.h"
#include "dynamics.h"
#include "state.h"
#include "utils.h"


/*esta es una funcion desactualizada que utilizamos durante simulaciones para hacer debbuging.
ahora mismo, no se compila. lo que hacia la funcion era medir las series de tiempo de xc1 y xc2
y guardar todos los detalles.*/
#if SAVE_SERIES
void time_loop(uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g,params lambda, u_min_max u,
                double *xc_1, double *xc_2, int *N_control, 
                double *xc_1_med, double *xc_2_med,
                double *xc_1_sigma, double *xc_2_sigma)
{
    int j,i;
    double epsilon1,epsilon2,aux;
    double W_med_sigma[8]={0};
    uint8_t *aux_pointer;

    /*detectar cuando xc alcanza un valor estable*/
    i=0;
    while(i<T_MAX)
    {
        time_step(gamma_old,gamma_new,g,lambda,u);
        xc_1[i]=xc1(gamma_new);
        xc_2[i]=xc2(gamma_new);
        i++;
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;

        if(i%W==0)
        {
            medvar(xc_1+i-W,W,W_med_sigma+4,W_med_sigma+5);
            medvar(xc_2+i-W,W,W_med_sigma+6,W_med_sigma+7);
            epsilon1=3*W_med_sigma[5]/sqrt(W);
            epsilon2=3*W_med_sigma[7]/sqrt(W);
            if(fabs(W_med_sigma[0]-W_med_sigma[4])<=epsilon1
                &&fabs(W_med_sigma[2]-W_med_sigma[6])<=epsilon2
                &&i>=2*W)
                break;
            else
            {
                for(j=0;j<=3;j++)
                {
                    aux=W_med_sigma[j];
                    W_med_sigma[j]=W_med_sigma[4+j];
                    W_med_sigma[4+j]=aux;
                }
            }
        }
    }

    /*medir xc*/
    *N_control=i;
    for(j=0;j<T_MCS;j++)
    {
        time_step(gamma_old,gamma_new,g,lambda,u);
        xc_1[i+j]=xc1(gamma_new);
        xc_2[i+j]=xc2(gamma_new);
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;
    }

    medvar(xc_1+i,T_MCS,xc_1_med,xc_1_sigma);
    medvar(xc_2+i,T_MCS,xc_2_med,xc_2_sigma);
}

#else

/*esta funcion mide las series de tiempo de xc1 y xc2, y detecta cuando alcanzan un valor estable.
lo que devuelve es la media y la desviacion estandar de las mediciones.*/
void time_loop(uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g,params lambda, u_min_max u,
                double *xc_1_med, double *xc_2_med, double *xc_1_sigma, 
                double *xc_2_sigma, double *c_med, double *c_sigma)
{
    int i,j;
    double epsilon1,epsilon2,aux;
    /*para detectar si la serie es estacionaria, medimos media y varianza sobre
    ventanas desplazadas de tamaño W, especificado en el archivo de configuracion*/
    double W_med_sigma[8]={0};
    double xc_1[W]={0}, xc_2[W]={0};
    double xc_1_measure[T_MCS]={0}, xc_2_measure[T_MCS]={0};

    /*la actualizacion se hace en paralelo. necesitamos 2 copias de gamma.
    en lugar de copiar una dentro de otra cada vez, creamos un puntero auxiliar,
    e intercambiamos los punteros de las dos copias de gamma de forma mas eficiente*/
    uint8_t *aux_pointer;


    i=0;
    /*el bucle principal de la simulacion. el tiempo de relajacion maximo permitido
    es T_MAX especificado en el archivo de configuracion*/
    while(i<T_MAX)
    {
        /*primero actualizamos el sistema*/
        time_step(gamma_old,gamma_new,g,lambda,u);
        /*medimos los observables y los guardamos en el vector en ventanas de tamaño W*/
        xc_1[i%W]=xc1(gamma_new);
        xc_2[i%W]=xc2(gamma_new);
        i++;
        /*intercambiar punteros de gamma*/
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;

        /*si estamos en el limite de una ventana*/
        if(i%W==0)
        {
            /*calculamos media y varianza dentro de la ventana*/
            medvar(xc_1,W,W_med_sigma+4,W_med_sigma+5);
            medvar(xc_2,W,W_med_sigma+6,W_med_sigma+7);
            /*la condicion de estacionareidad es la siguiente: 
            - comparamos media y varianza de ventanas consecutivas.
            - si ocurre que la diferencia entre medias es menor que un umbral, es estacionaria
            - el umbral se define como 3 veces la desviacion estandar de la ventana, dividido por la raiz cuadrada del tamaño de la ventana.
              de este modo, la condicion se hace independiente del tamaño de la ventana*/
            epsilon1=3*W_med_sigma[5]/sqrt(W);
            epsilon2=3*W_med_sigma[7]/sqrt(W);
            if(fabs(W_med_sigma[0]-W_med_sigma[4])<=epsilon1
                &&fabs(W_med_sigma[2]-W_med_sigma[6])<=epsilon2
                &&i>=2*W)
                break;
            else
            {
                /*intercambiamos las ventanas*/
                for(j=0;j<=3;j++)
                {
                    aux=W_med_sigma[j];
                    W_med_sigma[j]=W_med_sigma[4+j];
                    W_med_sigma[4+j]=aux;
                }
            }
        }
    }

    /*ahora, ya es estacionaria y/o se ha pasado del tiempo limite. 
    tomamos las medidas de los observables. un conjunto de T_MCS medidas de
    las que calculamos media y varianza*/
    /*medir xc*/
    for(i=0;i<T_MCS;i++)
    {
        time_step(gamma_old,gamma_new,g,lambda,u);
        xc_1_measure[i]=xc1(gamma_new);
        xc_2_measure[i]=xc2(gamma_new);
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;
    }

    medvar(xc_1_measure,T_MCS,xc_1_med,xc_1_sigma);
    medvar(xc_2_measure,T_MCS,xc_2_med,xc_2_sigma);
    
    *c_med=0.5*(*xc_1_med+*xc_2_med);
    *c_sigma=0.5*sqrt(*xc_1_sigma**xc_1_sigma+*xc_2_sigma**xc_2_sigma)/sqrt(T_MCS);
}

/*esta es la misma funicion que la anterior, pero devuelve el tiempo de relajacion*/
int time_loop_relax(uint8_t *gamma_old, uint8_t *gamma_new, const Graph *g,params lambda, u_min_max u,
                double *xc_1_med, double *xc_2_med, double *xc_1_sigma, 
                double *xc_2_sigma, double *c_med, double *c_sigma)
{
    int i,j,t_relax;
    double epsilon1,epsilon2,aux;
    double W_med_sigma[8]={0};
    double xc_1[W]={0}, xc_2[W]={0};
    double xc_1_measure[T_MCS]={0}, xc_2_measure[T_MCS]={0};
    uint8_t *aux_pointer;

    /*detectar cuando xc alcanza un valor estable*/
    i=0;
    t_relax=T_MAX;
    while(i<T_MAX)
    {
        time_step(gamma_old,gamma_new,g,lambda,u);
        xc_1[i%W]=xc1(gamma_new);
        xc_2[i%W]=xc2(gamma_new);
        i++;
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;

        if(i%W==0)
        {
            medvar(xc_1,W,W_med_sigma+4,W_med_sigma+5);
            medvar(xc_2,W,W_med_sigma+6,W_med_sigma+7);
            epsilon1=3*W_med_sigma[5]/sqrt(W);
            epsilon2=3*W_med_sigma[7]/sqrt(W);
            if(fabs(W_med_sigma[0]-W_med_sigma[4])<=epsilon1
                &&fabs(W_med_sigma[2]-W_med_sigma[6])<=epsilon2
                &&i>=2*W)
                {
                    t_relax=i;
                    break;
                }

            else
            {
                for(j=0;j<=3;j++)
                {
                    aux=W_med_sigma[j];
                    W_med_sigma[j]=W_med_sigma[4+j];
                    W_med_sigma[4+j]=aux;
                }
            }
        }
    }

    /*medir xc*/
    for(i=0;i<T_MCS;i++)
    {
        time_step(gamma_old,gamma_new,g,lambda,u);
        xc_1_measure[i]=xc1(gamma_new);
        xc_2_measure[i]=xc2(gamma_new);
        aux_pointer=gamma_old;
        gamma_old=gamma_new;
        gamma_new=aux_pointer;
    }

    medvar(xc_1_measure,T_MCS,xc_1_med,xc_1_sigma);
    medvar(xc_2_measure,T_MCS,xc_2_med,xc_2_sigma);
    
    *c_med=0.5*(*xc_1_med+*xc_2_med);
    *c_sigma=0.5*sqrt(*xc_1_sigma**xc_1_sigma+*xc_2_sigma**xc_2_sigma)/sqrt(T_MCS);
    
    /*esto es lo unico que cambia. devuelve t_relax*/
    return t_relax;
}
#endif
