"""
phase_portraits_scenarios.py

Mean-field replicator dynamics for the 'Guerra de mafias' / interdependent
populations model. The script produces Fig.2-like phase portraits:
    - unit square x1 horizontal, x2 vertical
    - velocity modulus as background color
    - arrows for the vector-field direction
    - interior nullclines
    - fixed points, labels, and linear stability classification
    - no-limit-cycle certificate using Bendixson-Dulac / fallback checks

The model is the rescaled two-population system in the appendix of
Gomez-Gardenes et al., Phys. Rev. E 86, 056113 (2012).
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple

import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import root
from scipy.integrate import solve_ivp

from matplotlib.axes import Axes
from matplotlib.figure import Figure


# ---------------------------------------------------------------------
# 1. Model
# ---------------------------------------------------------------------


def F(x: np.ndarray, b: float, beta: float, r: float, p: float, eps: float) -> np.ndarray:
    """Vector field (dx1/dt, dx2/dt)."""
    x1, x2 = x
    A = 1.0 - b + r
    C = 1.0 - b + eps

    g1 = beta * (x1 * A - r) + p * (x2 * C - eps)
    g2 = (x2 * A - r) + beta * p * (x1 * C - eps)

    return np.array([
        x1 * (1.0 - x1) * g1,
        x2 * (1.0 - x2) * g2,
    ])


# ---------------------------------------------------------------------
# 2. Jacobian, fixed points, classification
# ---------------------------------------------------------------------


def jacobian_numeric(x: np.ndarray, b: float, beta: float, r: float, p: float, eps: float, h: float = 1e-6) -> np.ndarray:
    """Central finite-difference Jacobian."""
    x = np.asarray(x, dtype=float)
    J = np.zeros((2, 2), dtype=float)
    args = (b, beta, r, p, eps)

    for j in range(2):
        step = np.zeros(2)
        step[j] = h
        J[:, j] = (F(x + step, *args) - F(x - step, *args)) / (2.0 * h)

    return J


def classify_eigs(eigs: np.ndarray, tol: float = 1e-8) -> str:
    """Classify a planar fixed point from the eigenvalues of the Jacobian."""
    re = np.real(eigs)
    im = np.imag(eigs)

    if np.all(re < -tol):
        return "stable spiral" if np.any(np.abs(im) > tol) else "stable node"
    if np.all(re > tol):
        return "unstable spiral" if np.any(np.abs(im) > tol) else "unstable node"
    if np.any(re > tol) and np.any(re < -tol):
        return "saddle"
    if np.all(np.abs(re) <= tol) and np.any(np.abs(im) > tol):
        return "center/marginal"
    return "non-hyperbolic"


def fixed_point_name(x: np.ndarray, tol: float = 1e-5) -> str:
    """Name fixed points using the notation of the paper."""
    x1, x2 = x
    if abs(x1) < tol and abs(x2) < tol:
        return "D"
    if abs(x1) < tol and abs(x2 - 1) < tol:
        return "A"
    if abs(x1 - 1) < tol and abs(x2) < tol:
        return "B"
    if abs(x1 - 1) < tol and abs(x2 - 1) < tol:
        return "C"
    if abs(x1) < tol:
        return "A'"
    if abs(x2) < tol:
        return "B'"
    return "E"


@dataclass
class FixedPoint:
    name: str
    point: np.ndarray
    eigs: np.ndarray
    classification: str


def find_fixed_points(b: float, beta: float, r: float, p: float, eps: float, grid_size: int = 13, tol: float = 1e-9) -> List[FixedPoint]:
    """Find all fixed points in the closed unit square by multistart root finding."""
    args = (b, beta, r, p, eps)
    guesses = []
    line = np.linspace(0.0, 1.0, grid_size)
    for x1 in line:
        for x2 in line:
            guesses.append(np.array([x1, x2], dtype=float))

    # Explicitly seed the invariant boundaries and corners.
    guesses += [
        np.array([0.0, 0.0]), np.array([0.0, 1.0]),
        np.array([1.0, 0.0]), np.array([1.0, 1.0]),
        np.array([0.0, 0.5]), np.array([0.5, 0.0]),
        np.array([1.0, 0.5]), np.array([0.5, 1.0]),
        np.array([0.5, 0.5]),
    ]

    raw = []
    for guess in guesses:
        sol = root(lambda y: F(y, *args), guess, method="hybr")
        if not sol.success:
            continue
        xstar = np.clip(sol.x, 0.0, 1.0)
        if np.all(xstar >= -tol) and np.all(xstar <= 1.0 + tol):
            if np.linalg.norm(F(xstar, *args)) < 1e-7:
                if not any(np.linalg.norm(xstar - y) < 1e-5 for y in raw):
                    raw.append(xstar)

    raw = sorted(raw, key=lambda z: (round(float(z[0]), 8), round(float(z[1]), 8)))

    out: List[FixedPoint] = []
    for xstar in raw:
        J = jacobian_numeric(xstar, *args)
        eigs = np.linalg.eigvals(J)
        out.append(FixedPoint(
            name=fixed_point_name(xstar),
            point=xstar,
            eigs=eigs,
            classification=classify_eigs(eigs),
        ))
    return out


# ---------------------------------------------------------------------
# 3. Critical values and scenario logic
# ---------------------------------------------------------------------


@dataclass
class CriticalValues:
    bup_B: float
    bup_A: float
    bc_B: float
    bc_A: float
    rc_A: float
    rc_B: float


def critical_values(beta: float, r: float, p: float, eps: float) -> CriticalValues:
    """
    Critical values from the appendix, using eps < 0.

    bup_B = 1 - p eps / beta
    bup_A = 1 - beta p eps

    bc_B and bc_A are the loss-of-stability values of B' and A'.
    If a denominator is zero, the corresponding critical value is inf.
    """
    bup_B = 1.0 - p * eps / beta
    bup_A = 1.0 - beta * p * eps

    num = r**2 - (p * eps)**2
    den_B = (r + beta * p * eps) - p * (beta * r + p * eps)
    den_A = (beta * r + p * eps) - p * (r + beta * p * eps)

    bc_B = 1.0 + num / den_B if abs(den_B) > 1e-12 else np.inf
    bc_A = 1.0 + beta * num / den_A if abs(den_A) > 1e-12 else np.inf

    # Thresholds for stability of D. For eps < 0 these are positive.
    rc_A = -beta * p * eps
    rc_B = -p * eps / beta

    return CriticalValues(bup_B, bup_A, bc_B, bc_A, rc_A, rc_B)


TABLE_I_SEQUENCES: Dict[str, List[str]] = {
    "(i)": ["D,A,B", "D,A", "D"],
    "(ii₂)": ["A,B", "A", "A'", "E"],
    "(ii₁)": ["A,B", "A", "A'"],
    "(iii₁)": ["A,B", "A,B'", "A", "A'"],
    "(iii₂)": ["A,B", "A,B'", "A", "A'", "E"],
    "(iii₃)": ["A,B", "A,B'", "A',B'", "A'"],
    "(iii₄)": ["A,B", "A,B'", "A',B'", "A'", "E"],
}


def b_values_for_table_scenario(label: str, cv: CriticalValues) -> List[float]:
    """
    Build representative b values for the requested Table-I scenario.
    Values are placed between the relevant bifurcation thresholds.
    """
    b0 = 1.0 + 1e-3
    bB, bA, cB, cA = cv.bup_B, cv.bup_A, cv.bc_B, cv.bc_A

    def mid(u: float, v: float) -> float:
        return 0.5 * (u + v)

    def after(u: float) -> float:
        return u + max(0.05, 0.08 * abs(u))

    if label == "(i)":
        return [mid(b0, bB), mid(bB, bA), after(bA)]
    if label == "(ii₂)":
        return [mid(b0, bB), mid(bB, bA), mid(bA, cA), after(cA)]
    if label == "(ii₁)":
        return [mid(b0, bB), mid(bB, bA), after(bA)]
    if label == "(iii₁)":
        return [mid(b0, bB), mid(bB, cB), mid(cB, bA), after(bA)]
    if label == "(iii₂)":
        return [mid(b0, bB), mid(bB, cB), mid(cB, bA), mid(bA, cA), after(cA)]
    if label == "(iii₃)":
        return [mid(b0, bB), mid(bB, bA), mid(bA, cB), after(cB)]
    if label == "(iii₄)":
        return [mid(b0, bB), mid(bB, bA), mid(bA, cB), mid(cB, cA), after(cA)]
    raise ValueError(f"Unknown Table-I scenario: {label!r}")


# These are practical plotting examples. They are meant to make the seven
# Table-I row types visible. If you need strict reproduction of a precise
# parameter region, edit these values and inspect the printed critical values.
EXAMPLE_PARAMETER_SETS: Dict[str, Dict[str, float]] = {
    # Shared article-like choices whenever possible.
    # eps is epsilon in the article and should be negative.

    "(i)": dict(beta=1.25, r=0.160, p=0.30, eps=-0.40),

    # Escenario delicado: beta debe estar muy cerca de 1.
    "(ii₂)": dict(beta=1.01, r=0.000396, p=0.020, eps=-0.020),

    "(ii₁)": dict(beta=1.50, r=0.316, p=0.80, eps=-1.00),
    "(iii₁)": dict(beta=2.0, r=0.03, p=0.60, eps=-1.0),
    "(iii₂)": dict(beta=1.50, r=0.010, p=0.575, eps=-1.00),
    "(iii₃)": dict(beta=1.25, r=0.386, p=0.80, eps=-1.00),
    "(iii₄)": dict(beta=1.0, r=0.0, p=0.3, eps=-0.4),
}



# ---------------------------------------------------------------------
# 4. No-limit-cycle certificate
# ---------------------------------------------------------------------


def no_limit_cycle_certificate(b: float, beta: float, r: float, p: float, eps: float, tol: float = 1e-10) -> str:
    """
    Certify absence of interior limit cycles when possible.

    Main test:
        Bendixson-Dulac with B = 1/[x1(1-x1)x2(1-x2)].
        div(BF) = (1-b+r)[ beta/(x2(1-x2)) + 1/(x1(1-x1)) ].

    Therefore, if b != 1+r, no periodic orbit exists in the open square.
    For b = 1+r, a simple fallback identifies the possible interior point
    and uses its saddle character as an index-theory warning/certificate.
    """
    dulac_factor = 1.0 - b + r
    if abs(dulac_factor) > tol:
        sign = "negative" if dulac_factor < 0 else "positive"
        return f"No LC: Bendixson-Dulac, strict {sign} divergence in the open square."

    # Degenerate Dulac case: b = 1+r.
    denom1 = beta * p * (eps - r)
    denom2 = p * (eps - r)
    if abs(denom1) < tol or abs(denom2) < tol:
        return "LC test inconclusive: degenerate b=1+r and eps=r or p=0."

    x1s = (beta * p * eps + r) / denom1
    x2s = (p * eps + beta * r) / denom2

    if not (tol < x1s < 1.0 - tol and tol < x2s < 1.0 - tol):
        return "No LC: b=1+r and no interior fixed point; index argument rules out an interior periodic orbit."

    j12 = x1s * (1.0 - x1s) * p * (eps - r)
    j21 = x2s * (1.0 - x2s) * beta * p * (eps - r)
    detJ = -j12 * j21
    if detJ < -tol:
        return "No LC: b=1+r; the only interior fixed point is a saddle, so index +1 is impossible."

    return "LC test inconclusive: non-hyperbolic degenerate case."


# ---------------------------------------------------------------------
# 5. Plotting
# ---------------------------------------------------------------------


def plot_interior_nullclines(ax: Axes, b: float, beta: float, r: float, p: float, eps: float, n: int = 600) -> None:
    """Plot only the interior straight-line nullclines g1=0 and g2=0."""
    xs = np.linspace(0.0, 1.0, n)
    A = 1.0 - b + r
    C = 1.0 - b + eps

    # g1 = 0: beta*(x1*A-r) + p*(x2*C-eps)=0
    if abs(p * C) > 1e-12:
        y1 = (beta * r + p * eps - beta * A * xs) / (p * C)
        mask = (y1 >= 0.0) & (y1 <= 1.0)
        ax.plot(xs[mask], y1[mask], lw=1.33, color="darkorange", solid_capstyle="round")

    # g2 = 0: x2*A-r + beta*p*(x1*C-eps)=0
    if abs(A) > 1e-12:
        y2 = (r + beta * p * eps - beta * p * C * xs) / A
        mask = (y2 >= 0.0) & (y2 <= 1.0)
        ax.plot(xs[mask], y2[mask], lw=1.33, color="darkorange", solid_capstyle="round")


def plot_phase_panel(ax: Axes, b: float, beta: float, r: float, p: float, eps: float, panel_title: str = "", grid: int = 51, arrows: int = 17) -> List[FixedPoint]:
    """One Fig.2-like phase-portrait panel."""
    xs = np.linspace(0.0, 1.0, grid)
    ys = np.linspace(0.0, 1.0, grid)
    X, Y = np.meshgrid(xs, ys)
    U = np.zeros_like(X)
    V = np.zeros_like(Y)

    for i in range(grid):
        for j in range(grid):
            U[i, j], V[i, j] = F(np.array([X[i, j], Y[i, j]]), b, beta, r, p, eps)

    speed = np.sqrt(U**2 + V**2)
    pcm = ax.pcolormesh(X, Y, speed, shading="gouraud", cmap="GnBu_r")

    # Arrows, separated from background grid for readability.
    xa = np.linspace(0.04, 0.96, arrows)
    ya = np.linspace(0.04, 0.96, arrows)
    XA, YA = np.meshgrid(xa, ya)
    UA = np.zeros_like(XA)
    VA = np.zeros_like(YA)
    for i in range(arrows):
        for j in range(arrows):
            UA[i, j], VA[i, j] = F(np.array([XA[i, j], YA[i, j]]), b, beta, r, p, eps)
    norm = np.sqrt(UA**2 + VA**2)
    norm[norm == 0] = 1.0
    ax.quiver(XA, YA, UA / norm, VA / norm, angles="xy", scale_units="xy", scale=18, width=0.003, color="black", alpha=0.75)

    plot_interior_nullclines(ax, b, beta, r, p, eps)

    fps = find_fixed_points(b, beta, r, p, eps)
    for fp in fps:
        x, y = fp.point
        if "stable" in fp.classification and "unstable" not in fp.classification:
            marker, face = "o", "lime"
            ax.plot(x, y, marker=marker, ms=7.5, mec="black", mfc=face, mew=1.1, zorder=5)
            ax.text(x + 0.018, y + 0.018, fp.name, fontsize=12, color="limegreen", weight="bold", zorder=6)
        elif fp.classification == "saddle":
            marker, face = "o", "yellow"
            ax.plot(x, y, marker=marker, ms=5, mec="black", mfc=face, mew=0.5, zorder=5)
        elif "unstable" in fp.classification:
            marker, face = "o", "red"
            ax.plot(x, y, marker=marker, ms=5, mec="black", mfc=face, mew=0.5, zorder=5)
        else:
            marker, face = "o", "yellow"

    #ax.set_xlim(0.0, 1.0)
    #ax.set_ylim(0.0, 1.0)

    ax.set_xlim(-0.04, 1.04)
    ax.set_ylim(-0.04, 1.04)
    ax.set_aspect("equal", adjustable="box")
    ax.set_xlabel(r"$x_1$")
    ax.set_ylabel(r"$x_2$")
    ax.set_title(panel_title or rf"$b={b:.3f}$", fontsize=10, weight="bold")

    return fps


def plot_table_scenario(label: str, beta: float, r: float, p: float, eps: float, save: bool = True, outdir: str = ".") -> Figure:
    """Plot the full sequence of panels corresponding to one Table-I scenario."""
    label = label.lower()
    if label not in TABLE_I_SEQUENCES:
        raise ValueError(f"Unknown scenario {label!r}; choose one of {sorted(TABLE_I_SEQUENCES)}")

    cv = critical_values(beta, r, p, eps)
    bvals = b_values_for_table_scenario(label, cv)
    phases = TABLE_I_SEQUENCES[label]

    ncols = len(bvals)
    fig, axes = plt.subplots(1, ncols, figsize=(3.4 * ncols, 3.35), constrained_layout=True)
    if ncols == 1:
        axes = [axes]

    print("\n" + "=" * 72)
    print(f"TABLE-I SCENARIO {label}")
    print(f"parameters: beta={beta}, r={r}, p={p}, eps={eps}")
    print(f"critical values: bup_B={cv.bup_B:.6g}, bup_A={cv.bup_A:.6g}, "
          f"bc_B={cv.bc_B:.6g}, bc_A={cv.bc_A:.6g}, rc_A={cv.rc_A:.6g}, rc_B={cv.rc_B:.6g}")
    print("=" * 72)

    last_pcm = None
    for k, (ax, b) in enumerate(zip(axes, bvals)):
        phase = phases[min(k, len(phases) - 1)]
        title = rf"({chr(97+k)}) $b={b:.3f}$" + "\n" + f"attractors: {phase}"
        fps = plot_phase_panel(ax, b, beta, r, p, eps, title)
        print(f"\nb={b:.6g} | expected attractor set: {phase}")
        print(no_limit_cycle_certificate(b, beta, r, p, eps))
        for fp in fps:
            ev = ", ".join(f"{z.real:+.3g}{z.imag:+.3g}i" for z in fp.eigs)
            print(f"  {fp.name:>2s} at ({fp.point[0]:.5f}, {fp.point[1]:.5f}) | "
                  f"{fp.classification:>16s} | eigs: {ev}")

        # Recover last background artist for common colorbar.
        last_pcm = ax.collections[0]

    fig.suptitle(
        rf"Escenario {label} | $\beta={beta}$, $r={r}$, $p={p}$, $\epsilon={eps}$",
        fontsize=13,
        weight="bold",
    )
    if last_pcm is not None:
        fig.colorbar(last_pcm, ax=axes, shrink=0.82, label=r"$|\dot{\mathbf{x}}|$")

    if save:
        filename = f"{outdir.rstrip('/')}/scenario_{label}_phase_portraits.png"
        fig.savefig(filename, dpi=220, bbox_inches="tight")
        print(f"\nSaved: {filename}")

    return fig


def plot_all_scenarios(save: bool = True, outdir: str = ".") -> None:
    """Generate one figure per Table-I scenario using EXAMPLE_PARAMETER_SETS."""
    for label, params in EXAMPLE_PARAMETER_SETS.items():
        plot_table_scenario(label, **params, save=save, outdir=outdir)
    plt.show()


def crits(beta, r, p, eps):
    """Calculate critical bifurcation values."""
    bup_B = 1 - p * eps / beta
    bup_A = 1 - beta * p * eps

    den_B = (r + beta * p * eps) - p * (beta * r + p * eps)
    den_A = (beta * r + p * eps) - p * (r + beta * p * eps)

    bc_B = np.nan if abs(den_B) < 1e-12 else 1 + (r**2 - (p * eps)**2) / den_B
    bc_A = np.nan if abs(den_A) < 1e-12 else 1 + beta * (r**2 - (p * eps)**2) / den_A

    return bup_B, bup_A, bc_B, bc_A


#----------------------------------------------------------------------Aux 

def find_params_for_AB_A_Ap_E():
    """
    Search parameters for scenario (ii_2):

        A,B  ->  A  ->  A'  ->  E

    Correct conditions from the paper:

        rB < r < rA
        beta < betaA_c
        1 < bup_B < bup_A < bc_A

    where B' is not stable in this regime.
    """
    candidates = []

    for beta in np.linspace(1.01, 3.00, 100):
        for p in np.linspace(0.05, 0.90, 100):
            for eps in np.linspace(-2.0, -0.1, 100):

                rB = -p * eps / beta
                rA = -beta * p * eps

                if not (rB < rA):
                    continue

                # Search r directly inside the relevant interval.
                for r in np.linspace(rB * 1.001, rA * 0.999, 50):
                    bB, bA, bcB, bcA = crits(beta, r, p, eps)

                    if not (
                        np.isfinite(bB)
                        and np.isfinite(bA)
                        and np.isfinite(bcA)
                    ):
                        continue

                    # Scenario (ii): B' is not stable in this r-region.
                    if not (rB < r < rA):
                        continue

                    # betaA_c from Eq. (A21)
                    den_betaA = r - p**2 * eps

                    if abs(den_betaA) < 1e-12:
                        continue

                    betaA_c = p * (r - eps) / den_betaA

                    # Scenario (ii_2), not (ii_1)
                    if not (beta < betaA_c):
                        continue

                    # Correct bifurcation order for A,B -> A -> A' -> E
                    if not (1.0 < bB < bA < bcA):
                        continue

                    # Optional visual separation.
                    if not (bA > bB + 0.025):
                        continue

                    if not (bcA > bA + 0.025):
                        candidates.append({
                            "beta": beta,
                            "r": r,
                            "p": p,
                            "eps": eps,
                            "rB": rB,
                            "rA": rA,
                            "betaA_c": betaA_c,
                            "bB": bB,
                            "bA": bA,
                            "bcA": bcA,
                        })


                    # Optional reasonable plotting scale.
                    """
                    if bB < 3.0 and bA < 5.0 and bcA < 20.0:
                        candidates.append({
                            "beta": beta,
                            "r": r,
                            "p": p,
                            "eps": eps,
                            "rB": rB,
                            "rA": rA,
                            "betaA_c": betaA_c,
                            "bB": bB,
                            "bA": bA,
                            "bcA": bcA,
                        })
                    """


    return candidates

#----------------------------------------------------------------------Aux

# ---------------------------------------------------------------------
# 6. Main examples
# ---------------------------------------------------------------------


if __name__ == "__main__":
    # Option 1: reproduce an article-like symmetric sequence, Fig.2 style.
    # plot_table_scenario("(ii₂)", beta=1.1053, r=0.100, p=0.521, eps=-1.000, save=False)
    # plot_table_scenario("(iii₄)", beta=1.0, r=0.0, p=0.3, eps=-0.4, save=False)
    plot_table_scenario("(iii₁)", beta=2.0, r=0.03, p=0.60, eps=-1.0, save=False)
    plt.show()
    

    # Option 2: generate the seven Table-I visual sequences.
    # plot_all_scenarios(save=True, outdir=".")
    
    # Option 3: Search for valid parameter combinations
    """
    print("\nSearching for valid parameter combinations...")
    print("=" * 80)
    cands = find_params_for_AB_A_Ap_E()
    
    print(f"Total candidates found: {len(cands)}")
    print("=" * 80)
    
    # Save first 50 candidates to a file
    output_file = "valid_parameters.txt"
    with open(output_file, "w") as f:
        f.write("Valid Parameter Combinations\n")
        f.write("=" * 100 + "\n")
        f.write(f"Total candidates found: {len(cands)}\n")
        f.write("=" * 100 + "\n\n")
        f.write("First 50 valid parameter sets:\n")
        f.write("-" * 100 + "\n")
        f.write(f"{'#':>3} | {'beta':>7} | {'r':>8} | {'p':>6} | {'eps':>7} | {'bB':>8} | {'bA':>8} | {'bcA':>8}\n")
        f.write("-" * 100 + "\n")
        
        for i, c in enumerate(cands[:50]):
            f.write(f"{i+1:3d} | {c['beta']:7.4f} | {c['r']:8.5f} | {c['p']:6.3f} | {c['eps']:7.2f} | "
                   f"{c['bB']:8.5f} | {c['bA']:8.5f} | {c['bcA']:8.5f}\n")
            print(f"#{i+1:3d}: beta={c['beta']:.4f}, r={c['r']:.5f}, p={c['p']:.3f}, eps={c['eps']:.2f} "
                  f"→ bB={c['bB']:.5f}, bA={c['bA']:.5f}, bcA={c['bcA']:.5f}")
    
    print("\n" + "=" * 80)
    print(f"Results saved to: {output_file}")
    print("=" * 80)
    """
    

    
