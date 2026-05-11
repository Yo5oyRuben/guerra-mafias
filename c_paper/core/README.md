# Núcleo de la simulación

Esta carpeta contiene la implementación de la dinámica microscópica.

- `rng.*`  
  Generación de números aleatorios.

- `graph.*`  
  Construcción y almacenamiento de los grafos Erdős-Rényi.

- `state.*`  
  Inicialización del microestado y cálculo de observables macroscópicos.

- `payoff.*`  
  Cálculo de los pagos asociados a las interacciones intra- e interpoblacionales.

- `dynamics.*`  
  Implementación de las distintas reglas microscópicas de actualización temporal.

- `sim.*`  
  Bucle principal de simulación (`time_loop`), encargado de evolucionar el sistema temporalmente, detectar estacionariedad,  medir observables y calcular medias y fluctuaciones.

- `utils.*, io.*`  
  Funciones auxiliares.