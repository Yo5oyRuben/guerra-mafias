#include <stdlib.h>
#include "types.h"
#include "rng.h"
#include "graph.h"

/*esta funcion, dado un conjunto de parametros, construye un grafo Erdos-Renyi aleatorio*/
void initial_ER(Graph *g, double p11, double p12, double p22, unsigned int seed)
{
   int i,j;
   int deg[NTOT]={0}, next[NTOT]={0};
   g->m=0;

   /*el problema es que no sabemos cual es el grado de cada nodo a priori, y no sabemos
   m, este es, el numero de aristas. por ello, tenemos primero que determinar cual es el numero de aristas,
   y despues asignar a g->col_idx un tamaño acorde utilizando asignacion dinamica de memoria.*/
   
   /*hacemos una primera pasada para contar grados y contar cuanto vale m.
   distinguimos si estamos estableciendo aristas dentro o entre subgrafos.*/
   rng_seed(seed);
   /*W11*/
   for(i=0;i<N1;i++)
   {
      for(j=i+1;j<N1;j++)
      {
         if(fran()<p11)
         {
            deg[i]++;
            deg[j]++;
            g->m+=2;
         }
      }
   }
   /*W22*/
   for(i=N1;i<NTOT;i++)
   {
      for (j=i+1;j<NTOT;j++)
      {
         if(fran()<p22)
         {
            deg[i]++;
            deg[j]++;
            g->m+=2;
         }
      }
   }
   /*W12=W21. es simetrica por bloques, asi que solo 
   necesitamos recorrer una de las mitades*/
   for(i=0;i<N1;i++)
   {
      for(j=N1;j<NTOT;j++)
      {
         if(fran()<p12)
         {
            deg[i]++;
            deg[j]++;
            g->m+=2;
         }
      }
   }

   /*ahora, asignamos memoria para col_idx, y rellenamos row_ptr.
   recordemos que row_ptr se define como un vector de tamaño NTOT+1 que a cada
   nodo le asigna el indice de su primera arista en col_idx. por ello, 
   row_ptr[i+1]-row_ptr[i] es el grado del nodo i.*/
   g->row_ptr[0]=0;
   for(i=0;i<NTOT;i++)
   {
      g->row_ptr[i+1]=g->row_ptr[i]+deg[i];
      next[i]=g->row_ptr[i];
   }
   g->col_idx=(int*)malloc(g->m*sizeof(int));

   /*ahora, hacemos una segunda pasada para rellenar col_idx.
   reinicializamos la semilla del generador de numeros aleatorios, es decir, la 
   secuencia de numeros aleatorios que va a salir es la misma exactamente*/
   rng_seed(seed);

   /*next es un vector que almacena el indice de la proxima arista que se va a asignar a cada nodo.
   empieza en 0 y se incrementa en 1 a medida que asignamis aristas al mismo nodo*/
   /*W11*/
   for(i=0;i<N1;i++)
   {
      for(j=i+1;j<N1;j++)
      {
         if(fran()<p11)
         {
            g->col_idx[next[i]]=j; next[i]++;
            g->col_idx[next[j]]=i; next[j]++;
         }
      }
   }
   /*W22*/
   for(i=N1;i<NTOT;i++)
   {
      for(j=i+1;j<NTOT;j++)
      {
         if(fran()<p22)
         {
            g->col_idx[next[i]]=j; next[i]++;
            g->col_idx[next[j]]=i; next[j]++;
         }
      }
   }
   /*W12=W21*/
   for(i=0;i<N1;i++)
   {
      for(j=N1;j<NTOT;j++)
      {
         if(fran()<p12)
         {
            g->col_idx[next[i]]=j; next[i]++;
            g->col_idx[next[j]]=i; next[j]++;
         }
      }
   }

   /*ahora, calculamos los grados intra y inter-subgrafos para cada nodo.
   esto se podría haber hecho antes, pero como no lo llegamos a necesitar hasta tener
    mas avanzado el proyecto, lo añadimos despues en una funcion separada*/
   for(i=0;i<NTOT;i++) split_degrees_i(g,i);

   /*el free de la memoria asignada a col_idx se hace en el main*/
}

/*esta funcion, dado un nodo i, calcula sus grados intra y inter-subgrafos*/
void split_degrees_i(Graph *g, int i)
{
   int k,j;
   g->k_inter[i]=0;
   g->k_intra[i]=0;
   /*recorremos la aristas del nodo i*/
   for(k=g->row_ptr[i];k<g->row_ptr[i+1];k++)
   {
      /*este es el indice del nodo adyacente*/
      j=g->col_idx[k];
      /*ahora, miramos si los dos nodos pertenecen al mismo subgrafo, o no*/
      if((i<N1&&j<N1)||(i>=N1&&j>=N1)) g->k_intra[i]++;
      else g->k_inter[i]++;
   }
}
