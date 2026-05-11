# -*- coding: utf-8 -*-
"""
Created on Mon May 11 13:55:15 2026

@author: Audru
"""
import math


def bifurcaciones(beta, r, epsilon, p, tol=1e-12):
    """
    Calcula las bifurcaciones en b del modelo del paper:
    Evolutionary dynamics on interdependent populations.

    Parámetros:
    beta = N1/N2, se asume beta >= 1
    r = payoff P intrapoblacional para D-D, con r >= 0
    epsilon = payoff P interpoblacional para D-D, con epsilon < 0
    p = probabilidad/fracción de enlaces interpoblacionales

    Devuelve:
    escenario, secuencia y valores de bifurcación relevantes.
    """

    if beta < 1:
        raise ValueError("El paper asume beta = N1/N2 >= 1. Si beta < 1, intercambia las poblaciones.")

    if epsilon >= 0:
        raise ValueError("En el paper epsilon debe ser negativo: epsilon < 0.")

    if p < 0 or p > 1:
        raise ValueError("p debe estar entre 0 y 1.")

    # Bifurcaciones de los estados polarizados A y B
    b_up_B = 1 - (p * epsilon) / beta
    b_up_A = 1 - beta * p * epsilon

    # Bifurcaciones de los estados quasipolarizados B' y A'
    denom_B = (r + beta * p * epsilon) - p * (beta * r + p * epsilon)
    denom_A = (beta * r + p * epsilon) - p * (r + beta * p * epsilon)

    b_c_B = None
    b_c_A = None

    if abs(denom_B) > tol:
        b_c_B = 1 + (r**2 - (p * epsilon)**2) / denom_B

    if abs(denom_A) > tol:
        b_c_A = 1 + beta * (r**2 - (p * epsilon)**2) / denom_A

    # Valores críticos para decidir el escenario
    r_A_c = -beta * p * epsilon
    r_B_c = -(p / beta) * epsilon

    denom_beta_A = r - (p**2) * epsilon
    if abs(denom_beta_A) > tol:
        beta_A_c = p * (r - epsilon) / denom_beta_A
    else:
        beta_A_c = math.inf

    resultado = {
        "parametros": {
            "beta": beta,
            "r": r,
            "epsilon": epsilon,
            "p": p
        },
        "valores_crudos": {
            "b_up_B": b_up_B,
            "b_up_A": b_up_A,
            "b_c_B": b_c_B,
            "b_c_A": b_c_A,
            "r_A_c": r_A_c,
            "r_B_c": r_B_c,
            "beta_A_c": beta_A_c
        },
        "escenario": None,
        "secuencia": None,
        "bifurcaciones_relevantes": {}
    }

    # Escenario (a)
    if r > r_A_c + tol:
        resultado["escenario"] = "(a)"
        resultado["secuencia"] = "D,A,B --b_up_B--> D,A --b_up_A--> D"
        resultado["bifurcaciones_relevantes"] = {
            "b_up_B": b_up_B,
            "b_up_A": b_up_A
        }
        return resultado

    # Escenarios (b) y (c)
    if r_B_c + tol < r < r_A_c - tol:
        if beta < beta_A_c - tol:
            resultado["escenario"] = "(b)"
            resultado["secuencia"] = "A,B --b_up_B--> A --b_up_A--> A' --b_c_A--> E"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_up_A": b_up_A,
                "b_c_A": b_c_A
            }
        else:
            resultado["escenario"] = "(c)"
            resultado["secuencia"] = "A,B --b_up_B--> A --b_up_A--> A'"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_up_A": b_up_A
            }
        return resultado

    # Escenarios (d), (e), (f), (g)
    if r < r_B_c - tol:
        has_bc_A = beta < beta_A_c - tol

        if b_c_B is None:
            raise ValueError("No se pudo calcular b_c_B por denominador casi cero.")

        bc_B_antes_de_bup_A = b_c_B < b_up_A

        if bc_B_antes_de_bup_A and not has_bc_A:
            resultado["escenario"] = "(d)"
            resultado["secuencia"] = "A,B --b_up_B--> A,B' --b_c_B--> A --b_up_A--> A'"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_c_B": b_c_B,
                "b_up_A": b_up_A
            }

        elif bc_B_antes_de_bup_A and has_bc_A:
            resultado["escenario"] = "(e)"
            resultado["secuencia"] = "A,B --b_up_B--> A,B' --b_c_B--> A --b_up_A--> A' --b_c_A--> E"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_c_B": b_c_B,
                "b_up_A": b_up_A,
                "b_c_A": b_c_A
            }

        elif not bc_B_antes_de_bup_A and not has_bc_A:
            resultado["escenario"] = "(f)"
            resultado["secuencia"] = "A,B --b_up_B--> A,B' --b_up_A--> A',B' --b_c_B--> A'"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_up_A": b_up_A,
                "b_c_B": b_c_B
            }

        else:
            resultado["escenario"] = "(g)"
            resultado["secuencia"] = "A,B --b_up_B--> A,B' --b_up_A--> A',B' --b_c_B--> A' --b_c_A--> E"
            resultado["bifurcaciones_relevantes"] = {
                "b_up_B": b_up_B,
                "b_up_A": b_up_A,
                "b_c_B": b_c_B,
                "b_c_A": b_c_A
            }

        return resultado

    resultado["escenario"] = "caso frontera"
    resultado["secuencia"] = "Los parámetros están sobre una frontera crítica; revisar estabilidad numéricamente."
    return resultado


# Ejemplo con los parámetros de tu foto
res = bifurcaciones(beta=1.5, r=0.316, epsilon=-1.0, p=0.8)

print("Escenario:", res["escenario"])
print("Secuencia:", res["secuencia"])
print("Bifurcaciones relevantes:")
for nombre, valor in res["bifurcaciones_relevantes"].items():
    print(f"  {nombre} = {valor:.12f}")

print("\nTodos los valores crudos calculados:")
for nombre, valor in res["valores_crudos"].items():
    print(f"  {nombre} = {valor}")
