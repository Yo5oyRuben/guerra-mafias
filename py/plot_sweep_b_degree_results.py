from __future__ import annotations

import re
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import pandas as pd


COLUMNS = ["b", "x1_mean", "x1_sem", "x2_mean", "x2_sem", "c_mean", "c_sem"]
COLORS = [
    "#111111",
    "#1f77b4",
    "#d62728",
    "#2ca02c",
    "#9467bd",
    "#8c564b",
    "#e377c2",
    "#17becf",
]


def read_metadata(path: Path) -> dict[str, str]:
    metadata: dict[str, str] = {}
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith("#"):
                break
            parts = line[1:].strip().split(maxsplit=1)
            if len(parts) == 2:
                metadata[parts[0]] = parts[1]
    return metadata


def read_run(path: Path) -> tuple[float, float, pd.DataFrame, dict[str, str]]:
    metadata = read_metadata(path)
    alpha = float(metadata.get("DEGREE_ALPHA", alpha_from_name(path.name)))
    p12 = float(metadata["P12"])
    df = pd.read_csv(path, sep=r"\s+", comment="#", names=COLUMNS, engine="python")
    return alpha, p12, df, metadata


def alpha_from_name(name: str) -> float:
    match = re.search(r"_alpha_([0-9]+(?:p[0-9]+)?)_", name)
    if not match:
        return 1.0
    return float(match.group(1).replace("p", "."))


def style(ax: plt.Axes, title: str, ylabel: str) -> None:
    ax.set_xlabel("$b$")
    ax.set_ylabel(ylabel)
    ax.set_title(title)
    ax.set_xlim(1, 4)
    ax.set_ylim(-0.03, 1.03)
    ax.grid(True, color="#dddddd", linewidth=0.8, alpha=0.75)
    ax.minorticks_on()
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)


def save(fig: plt.Figure, out_dir: Path, stem: str) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_dir / f"{stem}.png", dpi=240)
    fig.savefig(out_dir / f"{stem}.pdf")
    plt.close(fig)


def plot_group(
    runs: list[tuple[float, float, pd.DataFrame, dict[str, str]]],
    out_dir: Path,
    stem: str,
    title: str,
    legend_title: str,
    legend_label,
    ycol: str,
    ecol: str,
    ylabel: str,
) -> None:
    if not runs:
        return

    fig, ax = plt.subplots(figsize=(8.8, 5.6), constrained_layout=True)
    for idx, (alpha, p12, df, _metadata) in enumerate(runs):
        color = COLORS[idx % len(COLORS)]
        ax.plot(df["b"], df[ycol], color=color, linewidth=2.0, label=legend_label(alpha, p12))
        ax.fill_between(
            df["b"],
            df[ycol] - df[ecol],
            df[ycol] + df[ecol],
            color=color,
            alpha=0.13,
            linewidth=0,
        )

    style(ax, title, ylabel)
    ax.legend(title=legend_title, frameon=False, ncols=2, fontsize=9)
    save(fig, out_dir, stem)


def plot_paper_p(exp_dir: Path) -> None:
    raw_dir = exp_dir / "raw"
    out_dir = exp_dir / "plots"
    pattern = re.compile(r"fig4_degree_paper_p_alpha_1_p12_.*\.tsv$")
    runs = sorted(
        (read_run(path) for path in raw_dir.glob("*.tsv") if pattern.match(path.name)),
        key=lambda item: item[1],
    )
    if not runs:
        return

    first_metadata = runs[0][3]
    subtitle = (
        f"N1={first_metadata['N1']}, N2={first_metadata['N2']}, reps={first_metadata['reps']}, "
        f"alpha=1, clamp=[1/3,3]"
    )
    plot_group(
        runs,
        out_dir,
        "fig4_degree_alpha1_paper_p12_x1_mean",
        "Fig. 4 degree-weighted linear update\n" + subtitle,
        "$p_{12}$",
        lambda _alpha, p12: f"{p12:g}",
        "x1_mean",
        "x1_sem",
        "$c_1$",
    )
    plot_group(
        runs,
        out_dir,
        "fig4_degree_alpha1_paper_p12_c_mean",
        "Global cooperation, degree-weighted linear update\n" + subtitle,
        "$p_{12}$",
        lambda _alpha, p12: f"{p12:g}",
        "c_mean",
        "c_sem",
        "$c$",
    )


def plot_alpha_sweep(exp_dir: Path) -> None:
    raw_dir = exp_dir / "raw"
    out_dir = exp_dir / "plots"
    pattern = re.compile(r"fig4_degree_alpha_sweep_p0p1_alpha_.*\.tsv$")
    runs = sorted(
        (read_run(path) for path in raw_dir.glob("*.tsv") if pattern.match(path.name)),
        key=lambda item: item[0],
    )
    if not runs:
        return

    first_metadata = runs[0][3]
    subtitle = (
        f"N1={first_metadata['N1']}, N2={first_metadata['N2']}, p12={float(first_metadata['P12']):g}, "
        f"reps={first_metadata['reps']}, clamp=[1/3,3]"
    )
    plot_group(
        runs,
        out_dir,
        "fig4_degree_p0p1_alpha_sweep_x1_mean",
        "Degree-weighted linear update: alpha sweep\n" + subtitle,
        r"$\alpha$",
        lambda alpha, _p12: f"{alpha:g}",
        "x1_mean",
        "x1_sem",
        "$c_1$",
    )
    plot_group(
        runs,
        out_dir,
        "fig4_degree_p0p1_alpha_sweep_c_mean",
        "Global cooperation: alpha sweep\n" + subtitle,
        r"$\alpha$",
        lambda alpha, _p12: f"{alpha:g}",
        "c_mean",
        "c_sem",
        "$c$",
    )


def main() -> None:
    exp_dir = Path("c_paper/out/experiments/fig4_degree_linear_alpha1_and_alpha_sweep_2026-05-10")
    plot_paper_p(exp_dir)
    plot_alpha_sweep(exp_dir)
    print(f"Wrote plots to {exp_dir / 'plots'}")


if __name__ == "__main__":
    main()
