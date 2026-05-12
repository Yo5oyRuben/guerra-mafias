# Simulación microscópica del modelo evolutivo en poblaciones interdependientes
Esta carpeta contiene el programa en C utilizado para simular la dinámica microscópica.

## Motivación

En el límite termodinámico y de población bien mezclada, el sistema puede describirse mediante ecuaciones deterministas para las densidades de cooperadores en cada población. 
Sin embargo, cuando se estudian poblaciones finitas o redes con conectividad baja es necesario simular explícitamente la dinámica microscópica.

## Sistema modelizado

El sistema está formado por dos poblaciones de tamaños $N_1$ y $N_2$.
Cada individuo puede encontrarse en uno de dos estados, que identificamos con
$0$ y $1$. Por tanto, el espacio de estados del sistema es

```math
\Gamma = \{0,1\}^{N_1+N_2}
```

La evolución temporal del sistema se describe mediante

$$
\gamma:\mathbb{R}^+ \longrightarrow \Gamma\qquad t \longmapsto \gamma(t),
$$

donde $\gamma(t)$ representa la configuración microscópica del sistema en el
instante $t$. Los observables son la fracción de cooperadores en cada población. El programa simula la evolución temporal del sistema a partir de una configuración inicial dada y permite estudiar tanto los regímenes transitorios como el comportamiento asintótico de la dinámica. Los grafos que consideramos son no dirigidos, de tipo Erdős-Rényi.

Las interacciones se dividen en dos tipos:
- **Interacciones intrapoblacionales**:  Dilema del prisionero.

- **Interacciones interpoblacionales**:  Chicken game.

  ## Organización del proyecto

- `core/`  
  Contiene el núcleo de la simulación. Aquí se implementan las estructuras de datos, la dinámica evolutiva, la generación de redes y otras varias funciones auxiliares.

- `apps/`  
  Contiene distintos programas ejecutables (`main`) utilizados para realizar experimentos concretos y barridos de parámetros. Muchos de los parámetros de simulación pueden cambiarse desde el archivo de configuracion `config.h`.

- `out/experiments`  
  Contiene los resultados ordenados generados por las simulaciones, nuestras explicaciones sobre la sucesión de experimentos que hemos hecho y alguna conclusión.