# Resolución analítica del sistema

En esta carpeta se estudia analíticamente el sistema dinámico usado en los retratos de fase del proyecto.

Partimos de la versión de campo medio reescalada implementada en:

`PhasePortraitsMeanField/phase_portraits_scenarios.py`

El sistema es

dx1/dt = x1(1-x1) g1(x1,x2)

dx2/dt = x2(1-x2) g2(x1,x2)

donde

g1 = beta (x1 A - r) + p (x2 C - eps)

g2 = (x2 A - r) + beta p (x1 C - eps)

con

A = 1 - b + r

C = 1 - b + eps

El objetivo de esta parte es obtener de forma simbólica:

1. Nulclinas.
2. Puntos fijos.
3. Jacobiano.
4. Condiciones generales de estabilidad.
5. Evaluación para conjuntos concretos de parámetros usados en las simulaciones.