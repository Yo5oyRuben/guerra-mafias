# Resolucion analitica

Esta carpeta contiene la parte simbolica del trabajo.

En `Resolucion_analitica.ipynb` partimos de las ecuaciones de campo medio del modelo y derivamos, paso a paso, las expresiones que luego usamos para interpretar los retratos de fase:

- las nulclinas del sistema;
- los puntos fijos de esquina, borde e interior;
- las condiciones para que esos puntos esten dentro del cuadrado fisico `0 <= x1,x2 <= 1`;
- el jacobiano del sistema;
- el criterio local de estabilidad de los puntos fijos.

`modelo_simbolico.py` contiene algunas funciones auxiliares de Sympy que usamos para construir el sistema y calcular nulclinas, puntos fijos y jacobianos.

`Resolucion_analitica_anexo.ipynb` guarda una version mas larga y detallada del desarrollo.
