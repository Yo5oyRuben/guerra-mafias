/* File: graph.c
 * Purpose: Implementa la logica de construccion y gestion de grafos dispersos.
 */

#include <stdlib.h>
#include "types.h"
#include "rng.h"

void initial_ER(Graph *g, double p11, double p12, double p22, unsigned int seed)
{
   int i,j;
   int deg[NTOT]={0}, next[NTOT]={0};
   g->m=0;

    /*primera pasada para guardar grados y contar cuanto vale m*/
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
            g->m += 2;
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
   /*W12=W21*/
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

   g->row_ptr[0]=0;
   for(i=0;i<NTOT;i++)
   {
      g->row_ptr[i+1]=g->row_ptr[i]+deg[i];
      next[i]=g->row_ptr[i];
   }
   g->col_idx=(int*)malloc(g->m*sizeof(int));

   /*segunda pasada para rellenar col_idx. misma semilla y numeros aleatorios*/
   rng_seed(seed);
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
}
