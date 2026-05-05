from __future__ import annotations

import argparse
import math
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Plot sweep-b simulations produced by run_sweep_b_stats."
    )
    parser.add_argument(
        "experiment_dir",
        nargs="?",
        default="c_paper/out/experiments/sweep_b_2026-05-04_escalated_parallel_independent",
        help="Experiment directory containing raw/*.tsv.",
    )
    return parser.parse_args()


def read_metadata(path: Path) -> dict[str, str]:
    metadata: dict[str, str] = {}
    with path.open("r", encoding="utf-8") as handle:
        for line in handle:
            if not line.startswith("#"):
                break
            clean = line[1:].strip()
            if not clean:
                continue
            parts = clean.split(maxsplit=1)
            if len(parts) == 2:
                metadata[parts[0]] = parts[1]
    return metadata


def fallback_p12(path: Path) -> float:
    match = re.search(r"_p12_([0-9p]+)\.tsv$", path.name)
    if not match:
        raise ValueError(f"Cannot infer p12 from {path}")
    return float(match.group(1).replace("p", "."))


def load_run(path: Path) -> tuple[float, pd.DataFrame, dict[str, str]]:
    metadata = read_metadata(path)
    p12 = float(metadata.get("P12", fallback_p12(path)))
    df = pd.read_csv(
        path,
        sep=r"\s+",
        comment="#",
        names=COLUMNS,
        engine="python",
    )
    return p12, df, metadata


def pretty_p12(value: float) -> str:
    return f"{value:g}"


def style_axes(ax: plt.Axes, xlabel: str, ylabel: str, title: str) -> None:
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.set_title(title, pad=10)
    ax.set_ylim(-0.03, 1.03)
    ax.grid(True, which="major", color="#d9d9d9", linewidth=0.8, alpha=0.75)
    ax.grid(True, which="minor", color="#eeeeee", linewidth=0.5, alpha=0.65)
    ax.minorticks_on()
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)


def plot_family(
    files: list[Path],
    y_column: str,
    err_column: str,
    ylabel: str,
    title: str,
    out_dir: Path,
    out_stem: str,
) -> None:
    runs = sorted((load_run(path) for path in files), key=lambda item: item[0])
    fig, ax = plt.subplots(figsize=(8.0, 5.2), constrained_layout=True)

    for idx, (p12, df, _metadata) in enumerate(runs):
        color = COLORS[idx % len(COLORS)]
        x = df["b"].to_numpy()
        y = df[y_column].to_numpy()
        err = df[err_column].to_numpy()
        ax.plot(x, y, color=color, linewidth=2.0, label=f"$p_{{12}}={pretty_p12(p12)}$")
        if not all(math.isnan(v) for v in err):
            ax.fill_between(x, y - err, y + err, color=color, alpha=0.14, linewidth=0)

    style_axes(ax, "$b$", ylabel, title)
    ax.legend(frameon=False, ncols=2, fontsize=9, handlelength=2.8)

    for suffix in ("png", "pdf"):
        fig.savefig(out_dir / f"{out_stem}.{suffix}", dpi=240)
    plt.close(fig)


def plot_combined_fig4(raw_dir: Path, out_dir: Path) -> None:
    families = [
        ("fig4_paper_p12_*.tsv", "paper", "-"),
        ("fig4_strong_coupling_p12_*.tsv", "strong", "--"),
    ]
    fig, ax = plt.subplots(figsize=(8.4, 5.4), constrained_layout=True)
    color_by_p12: dict[float, str] = {}
    color_index = 0

    for pattern, family_label, linestyle in families:
        for path in sorted(raw_dir.glob(pattern)):
            p12, df, _metadata = load_run(path)
            if p12 not in color_by_p12:
                color_by_p12[p12] = COLORS[color_index % len(COLORS)]
                color_index += 1
            ax.plot(
                df["b"],
                df["x1_mean"],
                color=color_by_p12[p12],
                linewidth=1.9,
                linestyle=linestyle,
                label=f"{family_label}: $p_{{12}}={pretty_p12(p12)}$",
            )

    style_axes(
        ax,
        "$b$",
        r"$c_1$",
        "Fig. 4: paper coupling and stronger coupling",
    )
    ax.legend(frameon=False, ncols=2, fontsize=8, handlelength=2.8)

    for suffix in ("png", "pdf"):
        fig.savefig(out_dir / f"fig4_paper_vs_strong_x1_mean.{suffix}", dpi=240)
    plt.close(fig)


def main() -> None:
    args = parse_args()
    experiment_dir = Path(args.experiment_dir)
    raw_dir = experiment_dir / "raw"
    out_dir = experiment_dir / "plots"
    out_dir.mkdir(parents=True, exist_ok=True)

    plot_family(
        sorted(raw_dir.glob("fig3_paper_p12_*.tsv")),
        y_column="c_mean",
        err_column="c_sem",
        ylabel=r"$c$",
        title="Fig. 3 parameters: global cooperation",
        out_dir=out_dir,
        out_stem="fig3_paper_c_mean",
    )
    plot_family(
        sorted(raw_dir.glob("fig4_paper_p12_*.tsv")),
        y_column="x1_mean",
        err_column="x1_sem",
        ylabel=r"$c_1$",
        title="Fig. 4 parameters: population 1 cooperation",
        out_dir=out_dir,
        out_stem="fig4_paper_x1_mean",
    )
    plot_family(
        sorted(raw_dir.glob("fig4_strong_coupling_p12_*.tsv")),
        y_column="x1_mean",
        err_column="x1_sem",
        ylabel=r"$c_1$",
        title="Fig. 4 geometry with stronger coupling",
        out_dir=out_dir,
        out_stem="fig4_strong_coupling_x1_mean",
    )
    plot_combined_fig4(raw_dir, out_dir)

    print(f"Wrote plots to {out_dir}")


if __name__ == "__main__":
    main()
