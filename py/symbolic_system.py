import sympy as sp

# Placeholders for symbolic analysis.
x1, x2, b, r, p, eps, N1, N2 = sp.symbols('x1 x2 b r p eps N1 N2', real=True)

f1 = x1*(1-x1)*((N1-1)*(x1*(1-b+r)-r) + N2*p*(x2*(1-b+eps)-eps))
f2 = x2*(1-x2)*((N2-1)*(x2*(1-b+r)-r) + N1*p*(x1*(1-b+eps)-eps))

print("f1 =", sp.expand(f1))
print("f2 =", sp.expand(f2))
