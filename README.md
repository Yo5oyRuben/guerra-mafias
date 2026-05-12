# Guerra de mafias en redes interdependientes

Este repositorio recoge un trabajo grupal de la asignatura de Caos y Sistemas Dinamicos No Lineales, de 3o de Fisica. Hemos estudiado la dinamica evolutiva de dos poblaciones acopladas sobre redes de Erdos-Renyi.

El punto de partida ha sido el articulo de Jesus Gomez-Gardenes, Carlos Gracia-Lazaro, Luis Mario Floria y Yamir Moreno, *Evolutionary dynamics on interdependent populations*, Phys. Rev. E 86, 056113 (2012). Primero hemos reconstruido sus resultados principales, y despues hemos usado el simulador para explorar que ocurre cuando el sistema deja de ser ideal y aparecen efectos de tamano finito, conectividad limitada y tiempos largos de relajacion.

En concreto, hemos trabajado en tres direcciones:

- resolucion analitica del modelo de campo medio, incluyendo nulclinas, puntos fijos, jacobiano, estabilidad y analisis de bifurcaciones;
- simulaciones microscopicas en C sobre redes de Erdos-Renyi, con barridos en `b`, condiciones iniciales y parametros de acoplo;
- analisis numerico de los resultados, comparando el limite termodinamico, altas conectividades, transiciones criticas y distintas reglas de copia.

La idea general del repositorio es dejar una traza clara de todo el proceso: la derivacion simbolica, los codigos de simulacion, los experimentos realizados y las figuras finales que usamos para interpretar los resultados.
