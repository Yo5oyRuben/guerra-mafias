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
    beta = float(metadata["FERMI_BETA"])
    p12 = float(metadata["P12"])
    df = pd.read_csv(path, sep=r"\s+", comment="#", names=COLUMNS, engine="python")
    return beta, p12, df, metadata


def style(ax: plt.Axes, title: str) -> None:
    ax.set_xlabel("$b$")
    ax.set_ylabel("$c_1$")
    ax.set_title(title)
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


def plot_single_beta(exp_dir: Path) -> None:
    raw_dir = exp_dir / "raw"
    out_dir = exp_dir / "plots"
    runs = sorted((read_run(path) for path in raw_dir.glob("fig4_fermi_beta_*_p12_*.tsv")), key=lambda item: item[1])
    if not runs:
        return

    beta = runs[0][0]
    fig, ax = plt.subplots(figsize=(8.4, 5.4), constrained_layout=True)
    for idx, (_beta, p12, df, _metadata) in enumerate(runs):
        color = COLORS[idx % len(COLORS)]
        ax.plot(df["b"], df["x1_mean"], color=color, linewidth=2.0, label=f"{p12:g}")
        ax.fill_between(
            df["b"],
            df["x1_mean"] - df["x1_sem"],
            df["x1_mean"] + df["x1_sem"],
            color=color,
            alpha=0.14,
            linewidth=0,
        )
    style(ax, f"Fig. 4 Fermi, beta={beta:g}")
    ax.legend(title="$p_{12}$", frameon=False, ncols=2, fontsize=9)
    save(fig, out_dir, f"fig4_fermi_beta_{beta:g}_x1_mean".replace(".", "p"))


def collect_runs(exp_dirs: list[Path]) -> dict[float, dict[float, pd.DataFrame]]:
    by_beta: dict[float, dict[float, pd.DataFrame]] = {}
    for exp_dir in exp_dirs:
        for path in (exp_dir / "raw").glob("fig4_fermi_beta_*_p12_*.tsv"):
            beta, p12, df, _metadata = read_run(path)
            by_beta.setdefault(beta, {})[p12] = df
    return by_beta


def plot_beta_grid(exp_dirs: list[Path], out_dir: Path) -> None:
    by_beta = collect_runs(exp_dirs)
    if not by_beta:
        return

    betas = sorted(by_beta)
    fig, axes = plt.subplots(1, len(betas), figsize=(5.2 * len(betas), 4.8), sharey=True, constrained_layout=True)
    if len(betas) == 1:
        axes = [axes]

    for ax, beta in zip(axes, betas):
        for idx, p12 in enumerate(sorted(by_beta[beta])):
            df = by_beta[beta][p12]
            ax.plot(df["b"], df["x1_mean"], color=COLORS[idx % len(COLORS)], linewidth=1.8, label=f"{p12:g}")
        style(ax, f"beta={beta:g}")
    axes[-1].legend(title="$p_{12}$", frameon=False, fontsize=8, loc="center left", bbox_to_anchor=(1.02, 0.5))
    save(fig, out_dir, "fig4_fermi_beta_grid_x1_mean")


def plot_selected_p12_by_beta(exp_dirs: list[Path], out_dir: Path) -> None:
    by_beta = collect_runs(exp_dirs)
    if not by_beta:
        return

    selected = [0.0, 0.005, 0.01, 0.02, 0.04]
    fig, axes = plt.subplots(1, len(selected), figsize=(4.4 * len(selected), 4.4), sharey=True, constrained_layout=True)
    for ax, p12 in zip(axes, selected):
        for idx, beta in enumerate(sorted(by_beta)):
            if p12 not in by_beta[beta]:
                continue
            df = by_beta[beta][p12]
            ax.plot(df["b"], df["x1_mean"], linewidth=1.9, color=COLORS[idx % len(COLORS)], label=f"beta={beta:g}")
        style(ax, f"$p_{{12}}={p12:g}$")
    axes[-1].legend(frameon=False, fontsize=8, loc="center left", bbox_to_anchor=(1.02, 0.5))
    save(fig, out_dir, "fig4_fermi_selected_p12_by_beta")


def plot_compare_linear(exp_dirs: list[Path], linear_dir: Path, out_dir: Path) -> None:
    by_beta = collect_runs(exp_dirs)
    if not by_beta or not linear_dir.exists():
        return

    beta = 5.0 if 5.0 in by_beta else sorted(by_beta)[0]
    p12_values = sorted(by_beta[beta])
    fig, axes = plt.subplots(1, 2, figsize=(11.5, 4.8), sharey=True, constrained_layout=True)

    for idx, p12 in enumerate(p12_values):
        df = by_beta[beta][p12]
        axes[0].plot(df["b"], df["x1_mean"], color=COLORS[idx % len(COLORS)], linewidth=1.9, label=f"{p12:g}")

        tag = f"{p12:g}".replace(".", "p")
        linear_path = linear_dir / "raw" / f"fig4_paper_p12_{tag}.tsv"
        if linear_path.exists():
            linear_df = pd.read_csv(linear_path, sep=r"\s+", comment="#", names=COLUMNS, engine="python")
            axes[1].plot(linear_df["b"], linear_df["x1_mean"], color=COLORS[idx % len(COLORS)], linewidth=1.9, label=f"{p12:g}")

    style(axes[0], f"Fermi beta={beta:g}")
    style(axes[1], "Linear update")
    axes[1].legend(title="$p_{12}$", frameon=False, fontsize=8, loc="center left", bbox_to_anchor=(1.02, 0.5))
    save(fig, out_dir, "fig4_fermi_beta5_vs_linear")


def main() -> None:
    exp_dirs = [
        Path("c_paper/out/experiments/sweep_b_fig4_fermi_beta_1_full_2026-05-07"),
        Path("c_paper/out/experiments/sweep_b_fig4_fermi_beta_5_full_2026-05-07_run2"),
        Path("c_paper/out/experiments/sweep_b_fig4_fermi_beta_10_full_2026-05-07"),
    ]
    exp_dirs = [path for path in exp_dirs if path.exists()]
    comparison_dir = Path("c_paper/out/experiments/sweep_b_fig4_fermi_comparison_2026-05-09/plots")
    linear_dir = Path("c_paper/out/experiments/sweep_b_2026-05-04_escalated_parallel_independent")

    for exp_dir in exp_dirs:
        plot_single_beta(exp_dir)
    plot_beta_grid(exp_dirs, comparison_dir)
    plot_selected_p12_by_beta(exp_dirs, comparison_dir)
    plot_compare_linear(exp_dirs, linear_dir, comparison_dir)
    print(f"Wrote Fermi sweep plots for {len(exp_dirs)} experiments")


if __name__ == "__main__":
    main()
