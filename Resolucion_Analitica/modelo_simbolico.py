from __future__ import annotations

import sympy as sp


def crear_simbolos():
    """Crea los simbolos del sistema de campo medio reescalado."""
    x1, x2 = sp.symbols("x1 x2", real=True)
    b, beta, r, p, eps = sp.symbols("b beta r p eps", real=True)
    return x1, x2, b, beta, r, p, eps


def construir_sistema(x1, x2, b, beta, r, p, eps):
    """Construye A, C, g1, g2, F1 y F2."""
    A = 1 - b + r
    C = 1 - b + eps

    g1 = beta * (x1 * A - r) + p * (x2 * C - eps)
    g2 = (x2 * A - r) + beta * p * (x1 * C - eps)

    F1 = x1 * (1 - x1) * g1
    F2 = x2 * (1 - x2) * g2

    return {
        "A": sp.simplify(A),
        "C": sp.simplify(C),
        "g1": sp.simplify(g1),
        "g2": sp.simplify(g2),
        "F1": sp.factor(F1),
        "F2": sp.factor(F2),
    }


def calcular_nulclinas(x1, x2, sistema):
    """
    Calcula las nulclinas interiores g1 = 0 y g2 = 0 resueltas para x2.

    Ademas de estas nulclinas interiores, el sistema completo tambien tiene
    nulclinas de borde:
        x1 = 0, x1 = 1, x2 = 0, x2 = 1.

    Las expresiones generales corresponden al caso generico. No cubren casos
    degenerados donde se anulen denominadores relevantes, por ejemplo:
        A = 0, C = 0, p = 0, beta = 0.
    """
    g1 = sistema["g1"]
    g2 = sistema["g2"]

    nulclina_g1 = sp.solve(sp.Eq(g1, 0), x2)
    nulclina_g2 = sp.solve(sp.Eq(g2, 0), x2)

    return {
        "g1_igual_0_para_x2": sp.simplify(nulclina_g1[0]) if nulclina_g1 else None,
        "g2_igual_0_para_x2": sp.simplify(nulclina_g2[0]) if nulclina_g2 else None,
    }


def calcular_puntos_fijos_esquina():
    """Devuelve los cuatro puntos fijos triviales de las esquinas."""
    return {
        "esquina_00": (sp.Integer(0), sp.Integer(0)),
        "esquina_10": (sp.Integer(1), sp.Integer(0)),
        "esquina_01": (sp.Integer(0), sp.Integer(1)),
        "esquina_11": (sp.Integer(1), sp.Integer(1)),
    }


def calcular_puntos_fijos_borde(x1, x2, sistema):
    """
    Calcula posibles puntos fijos de borde.

    Estos puntos solo son fisicamente relevantes si sus coordenadas caen en
    [0, 1]. Las formulas corresponden al caso generico y no cubren todos los
    casos degenerados, como A = 0, C = 0, p = 0 o beta = 0.
    """
    g1 = sistema["g1"]
    g2 = sistema["g2"]

    x2_en_x1_0 = sp.solve(sp.Eq(g2.subs(x1, 0), 0), x2)
    x2_en_x1_1 = sp.solve(sp.Eq(g2.subs(x1, 1), 0), x2)
    x1_en_x2_0 = sp.solve(sp.Eq(g1.subs(x2, 0), 0), x1)
    x1_en_x2_1 = sp.solve(sp.Eq(g1.subs(x2, 1), 0), x1)

    return {
        "x1_0": (sp.Integer(0), sp.simplify(x2_en_x1_0[0]) if x2_en_x1_0 else None),
        "x1_1": (sp.Integer(1), sp.simplify(x2_en_x1_1[0]) if x2_en_x1_1 else None),
        "x2_0": (sp.simplify(x1_en_x2_0[0]) if x1_en_x2_0 else None, sp.Integer(0)),
        "x2_1": (sp.simplify(x1_en_x2_1[0]) if x1_en_x2_1 else None, sp.Integer(1)),
    }


def calcular_punto_fijo_interior(x1, x2, sistema):
    """
    Calcula el punto fijo interior resolviendo g1 = 0 y g2 = 0.

    El punto interior solo es fisico si:
        0 < x1* < 1 y 0 < x2* < 1.

    La solucion generica supone que el determinante del sistema lineal no se
    anula. En particular, esta expresion no cubre el caso degenerado:
        A**2 - p**2*C**2 = 0.
    """
    g1 = sistema["g1"]
    g2 = sistema["g2"]

    soluciones = sp.solve([sp.Eq(g1, 0), sp.Eq(g2, 0)], [x1, x2], dict=True)

    if not soluciones:
        return None

    solucion = soluciones[0]
    return {
        "x1": sp.simplify(solucion[x1]),
        "x2": sp.simplify(solucion[x2]),
    }


def calcular_jacobiano(x1, x2, sistema):
    """Calcula el jacobiano simbolico J = d(F1,F2)/d(x1,x2)."""
    F1 = sistema["F1"]
    F2 = sistema["F2"]

    J = sp.Matrix(
        [
            [sp.diff(F1, x1), sp.diff(F1, x2)],
            [sp.diff(F2, x1), sp.diff(F2, x2)],
        ]
    )

    return sp.simplify(J)


def evaluar_jacobiano_interior(x1, x2, jacobiano, punto_interior):
    """Evalua el jacobiano simbolico en el punto fijo interior."""
    if punto_interior is None:
        return None

    sustituciones = {
        x1: punto_interior["x1"],
        x2: punto_interior["x2"],
    }

    return sp.simplify(jacobiano.subs(sustituciones))


def calcular_traza_y_determinante(jacobiano):
    """Calcula traza y determinante de una matriz jacobiana."""
    if jacobiano is None:
        return None, None

    traza = sp.simplify(jacobiano.trace())
    determinante = sp.simplify(jacobiano.det())

    return traza, determinante


def imprimir_seccion(titulo, contenido):
    """Imprime una seccion con formato sencillo."""
    print("\n" + "=" * 80)
    print(titulo)
    print("=" * 80)
    print(contenido)


def main():
    x1, x2, b, beta, r, p, eps = crear_simbolos()
    sistema = construir_sistema(x1, x2, b, beta, r, p, eps)

    nulclinas = calcular_nulclinas(x1, x2, sistema)
    puntos_esquina = calcular_puntos_fijos_esquina()
    puntos_borde = calcular_puntos_fijos_borde(x1, x2, sistema)
    punto_interior = calcular_punto_fijo_interior(x1, x2, sistema)

    jacobiano = calcular_jacobiano(x1, x2, sistema)
    jacobiano_interior = evaluar_jacobiano_interior(x1, x2, jacobiano, punto_interior)
    traza_interior, determinante_interior = calcular_traza_y_determinante(jacobiano_interior)

    imprimir_seccion("Sistema", "")
    print("A  =", sistema["A"])
    print("C  =", sistema["C"])
    print("g1 =", sistema["g1"])
    print("g2 =", sistema["g2"])
    print("F1 =", sistema["F1"])
    print("F2 =", sistema["F2"])

    imprimir_seccion("Nulclinas interiores", "")
    print("g1 = 0, resuelta para x2:")
    print(nulclinas["g1_igual_0_para_x2"])
    print("\ng2 = 0, resuelta para x2:")
    print(nulclinas["g2_igual_0_para_x2"])
    print("\nNota: tambien existen las nulclinas de borde x1=0, x1=1, x2=0, x2=1.")
    print("Caso generico: estas formulas suponen denominadores no nulos.")

    imprimir_seccion("Puntos fijos de esquina", "")
    for nombre, punto in puntos_esquina.items():
        print(f"{nombre}: {punto}")

    imprimir_seccion("Puntos fijos de borde", "")
    print("x1 = 0:", puntos_borde["x1_0"])
    print("x1 = 1:", puntos_borde["x1_1"])
    print("x2 = 0:", puntos_borde["x2_0"])
    print("x2 = 1:", puntos_borde["x2_1"])
    print("\nNota: estos puntos solo son fisicos si caen en [0,1].")

    imprimir_seccion("Punto fijo interior", "")
    print(punto_interior)
    print("\nNota: solo es fisico si 0 < x1* < 1 y 0 < x2* < 1.")
    print("Caso generico: no cubre A**2 - p**2*C**2 = 0.")

    imprimir_seccion("Jacobiano general", jacobiano)

    imprimir_seccion("Jacobiano en el punto interior", jacobiano_interior)

    imprimir_seccion("Traza y determinante interiores", "")
    print("traza =", traza_interior)
    print("determinante =", determinante_interior)

    imprimir_seccion("Casos degenerados no tratados explicitamente", "")
    print("A = 0")
    print("C = 0")
    print("p = 0")
    print("beta = 0")
    print("A**2 - p**2*C**2 = 0")


if __name__ == "__main__":
    main()
