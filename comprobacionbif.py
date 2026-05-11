# -*- coding: utf-8 -*-
"""
Created on Mon May 11 14:28:30 2026

@author: Audru
"""

def calcular_bifurcaciones(epsilon, beta, r, p):
    """
    Calcula los cuatro valores de bifurcación:

    b_up_B = 1 - (p / beta) * epsilon
    b_up_A = 1 - beta * p * epsilon

    b_c_B = 1 + [r^2 - (p epsilon)^2] /
                 [(r + beta p epsilon) - p(beta r + p epsilon)]

    b_c_A = 1 + beta [r^2 - (p epsilon)^2] /
                 [(beta r + p epsilon) - p(r + beta p epsilon)]
    """

    b_up_B = 1 - (p / beta) * epsilon
    b_up_A = 1 - beta * p * epsilon

    denominador_B = (r + beta * p * epsilon) - p * (beta * r + p * epsilon)
    denominador_A = (beta * r + p * epsilon) - p * (r + beta * p * epsilon)

    if denominador_B == 0:
        b_c_B = None
    else:
        b_c_B = 1 + (r**2 - (p * epsilon)**2) / denominador_B

    if denominador_A == 0:
        b_c_A = None
    else:
        b_c_A = 1 + beta * (r**2 - (p * epsilon)**2) / denominador_A

    return b_up_B, b_up_A, b_c_B, b_c_A


# ============================
# Cambia aquí tus parámetros
# ============================

epsilon = -1.0
beta = 1.5
r = 0.316
p = 0.8

# ============================
# Cálculo
# ============================

b_up_B, b_up_A, b_c_B, b_c_A = calcular_bifurcaciones(
    epsilon=epsilon,
    beta=beta,
    r=r,
    p=p
)

print("Parámetros usados:")
print(f"epsilon = {epsilon}")
print(f"beta    = {beta}")
print(f"r       = {r}")
print(f"p       = {p}")

print("\nValores calculados:")
print(f"b_up_B = {b_up_B}")
print(f"b_up_A = {b_up_A}")

if b_c_B is None:
    print("b_c_B = no definido, denominador cero")
else:
    print(f"b_c_B = {b_c_B}")

if b_c_A is None:
    print("b_c_A = no definido, denominador cero")
else:
    print(f"b_c_A = {b_c_A}")