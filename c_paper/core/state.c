/* File: state.c
 * Purpose: Implementa operaciones sobre el estado dinamico del sistema.
 */
#include <stdint.h>
#include "graph.h"
#include "rng.h"

/*genera configuracion aleatoria con fraccion x01 de cooperadores en N1, y x02 en N2*/
void ini_rand_x0(uint8_t *gamma, double x01, double x02)
{
    int i,j;
    uint8_t aux;
    int K1=(int)(x01*N1), K2=(int)(x02*N2);
    for(i=0;i<N1;i++)
    {
        if(i<K1) gamma[i]=1;
        else gamma[i]=0;
    }
    for(i=N1;i<NTOT;i++)
    {
        if((i-N1)<K2) gamma[i]=1;
        else gamma[i]=0;
    }
    /*reordenar el array aleatoriamente*/
    for(i=N1-1;i>0;i--)
    {
        j=rng_int(i+1);
        aux=gamma[i];
        gamma[i]=gamma[j];
        gamma[j]=aux;
    }
    for(i=NTOT-1;i>N1;i--)
    {
        j=N1+rng_int(i+1-N1);
        aux=gamma[i];
        gamma[i]=gamma[j];
        gamma[j]=aux;
    }
}

/*genera una configuracion inicial donde cada individuo es cooperador con probabilidad p1 en N1, p2 en N2*/
void ini_rand_Pr(uint8_t *gamma, double p1, double p2)
{
    int i;
    for(i=0;i<N1;i++)
    {
        if(fran()<p1) gamma[i]=1;
        else gamma[i]=0;
    }
    for(i=N1;i<NTOT;i++)
    {
        if(fran()<p2) gamma[i]=1;
        else gamma[i]=0;
    }
}

/*configuracion inicial donde todos son cooperadores*/
void ini_C(uint8_t *gamma)
{
    int i;
    for(i=0;i<NTOT;i++) gamma[i]=1;
}

/*Configuracion inicial donde todos son deflectores*/
void ini_D(uint8_t *gamma)
{
    int i;
    for(i=0;i<NTOT;i++) gamma[i]=0;
}

/*Mide fraccion de cooperadores en N1*/
double xc1(const uint8_t *gamma)
{
    int i,j=0;
    for(i=0;i<N1;i++)
    {
        j+=gamma[i];
    }
    return (double)j/N1;
}

/*Mide la fraccion de cooperadores en N2*/
double xc2(const uint8_t *gamma)
{
    int i,j=0;
    for(i=N1;i<NTOT;i++)
    {
        j+=gamma[i];
    }
    return (double)j/N2;
}
