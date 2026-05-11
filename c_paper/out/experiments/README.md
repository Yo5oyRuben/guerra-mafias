# Experimentos y flujo de trabajo

Esta carpeta contiene los experimentos principales que hemos ido realizando durante el proyecto. Aquí explicaremos el recorrido que seguimos, es decir, cómo fuimos tomando decisiones a partir de los resultados que iban saliendo.

## 01_paper_baselines

Lo primero que hicimos fue intentar reproducir las figuras del paper original.

La figura 3 nos sale prácticamente clavada, lo cual fue una primera buena señal de que el código estaba funcionando correctamente.
Sin embargo, con la figura 4 no obtuvimos el mismo resultado. En nuestras simulaciones, la cooperación cae mucho más deprisa que en la figura del paper. Este desacuerdo nos hizo preguntarnos si realmente nuestra implementación era correcta o si había algún detalle microscópico de la simulación no especificado en el artículo que se nos estuviera escapando.

## 02_thermodynamic_limit_high_connectivity

Para comprobar si el problema estaba en nuestro código, estudiamos el límite termodinámico y el régimen de altas conectividades.

La idea era la siguiente. Aunque una simulación microscópica pueda diferir de las ecuaciones analíticas en redes finitas o poco conectadas, en el límite de poblaciones grandes y conectividad alta debería acercarse a lo predicho por las ecuaciones de campo medio.
Al hacer este estudio vimos que el sistema sí tiende a las predicciones analíticas en ese límite.

Además, durante este proceso encontramos una transición bastante interesante entre dos regímenes:

- un régimen donde las ecuaciones analíticas no describen prácticamente nada bien la simulación microscópica;
- otro régimen donde las predicciones analíticas empiezan a cumplirse con mucha precisión.

Lo llamativo es que el cambio entre ambos regímenes no parece gradual, sino bastante repentino: la calidad de las predicciones mejora de golpe al cruzar cierta zona del espacio de parámetros.

También observamos un critical slowing down muy marcado cerca de esta transición. Es decir, justo en la zona donde el sistema cambia de régimen, las simulaciones tardan muchísimo más en relajarse y alcanzar un comportamiento estacionario.

## 03_critical_transition

El critical slowing down hizo que no pudiéramos caracterizar esta transición con tanta profundidad como nos habría gustado, porque muchas simulaciones tardaban días, y no disponíamos de suficiente potencia de cálculo.

Aun así, intentamos estudiar parcialmente cómo cambia la hipersuperficie crítica al variar los parámetros del sistema. Es decir, exploramos cómo se desplaza la frontera entre el régimen donde las ecuaciones analíticas fallan y el régimen donde sí describen correctamente la dinámica microscópica.

Esta parte no la hemos llegado a cerrar. Solo mostramos que la transición existe, que parece bastante brusca y que depende de los parámetros del sistema.

## 04_update_rules

Después volvimos al problema inicial: por qué nuestra figura 4 no coincidía con la del paper.

La hipótesis principal que estudiamos fue que, aunque varias reglas microscópicas de copia puedan ser equivalentes en el límite termodinámico y de alta conectividad, pueden producir dinámicas diferentes fuera de ese régimen.

Esto es importante porque el paper no da muchos detalles sobre cómo implementaron exactamente la simulación microscópica. Por tanto, pequeñas diferencias en la probabilidad de copia podrían cambiar bastante el resultado en redes finitas.

Probamos tres reglas de actualización:

1. Una probabilidad de copia lineal con una normalización absoluta y bastante agresiva. Esta es la que hemos usado para todos los experimentos anteriores, ya que es la más eficiente para el ordenador.

2. Una probabilidad de copia de Fermi. Esta es lentísima y requiere mucho tiempo de cálculo. Sin embargo, es muy diferente a la anterior, pues permite cambios de estrategia a estrategias peores.

3. Una probabilidad lineal dependiente del grado del nodo.  
   Esta regla da más importancia a los nodos de mayor grado. Además, nos permite hacernos una idea de qué habría pasado si en la probabilidad lineal hubiéramos usado una normalización menos agresiva.

Estudiamos el límite termodinámico para las tres reglas y vimos que las ecuaciones analíticas parecen cumplirse en todos los casos.

Hay que tener cuidado, eso sí, con la regla lineal dependiente del grado: esta comprobación la hemos hecho usando redes de Erdős-Rényi, y no sabemos si el resultado seguiría siendo cierto para otras topologías.

Después regeneramos las figuras del paper usando estas distintas reglas. Los resultados cambian bastante: algunas reglas mueven la curva en una dirección más parecida a la del paper, mientras que otras la alejan.

En general, vimos que cuanto mayor es la probabilidad asignada a que un nodo cambie su bit cuando el nodo observado tiene mejor payoff, más parecida sale la curva a la figura del paper.

Nuestra conclusión es que el desacuerdo con la figura 4 no implica necesariamente que nuestro código esté mal. Como el paper no especifica todos los detalles microscópicos de la simulación, nuestros resultados no son incompatibles con los suyos. Probablemente varias implementaciones microscópicas sean igualmente válidas, especialmente fuera del límite termodinámico, donde esas diferencias sí pueden tener efectos visibles.