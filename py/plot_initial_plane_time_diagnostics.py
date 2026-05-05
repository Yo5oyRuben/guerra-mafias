from __future__ import annotations

import argparse
import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


COLUMNS = [
    "ix",
    "iy",
    "x1_0",
    "x2_0",
    "rep",
    "x1_inf",
    "x2_inf",
    "sigma_1",
    "sigma_2",
    "t_relax",
]


@dataclass(frozen=True)
class RunInfo:
    path: Path
    n1: int | None
    n2: int | None
    p11: float | None
    p12: float | None
    p22: float | None
    b: float | None
    r: float | None
    e: float | None
    ndiv: int | None
    reps: int | None


def parse_float_tag(value: str) -> float:
    return float(value.replace("m", "-").replace("p", "."))


def parse_int_tag(value: str) -> int:
    return int(value.replace("p", ""))


def parse_run_info(path: Path) -> RunInfo:
    name = path.stem
    patterns = {
        "n1": (r"N1_([^_]+)", parse_int_tag),
        "n2": (r"N2_([^_]+)", parse_int_tag),
        "p11": (r"P11_([^_]+)", parse_float_tag),
        "p12": (r"P12_([^_]+)", parse_float_tag),
        "p22": (r"P22_([^_]+)", parse_float_tag),
        "b": (r"B_([^_]+)", parse_float_tag),
        "r": (r"R_([^_]+)", parse_float_tag),
        "e": (r"E_([^_]+)", parse_float_tag),
        "ndiv": (r"ndiv_(\d+)", int),
        "reps": (r"reps_(\d+)", int),
    }
    values: dict[str, object] = {}
    for key, (pattern, parser) in patterns.items():
        match = re.search(pattern, name)
        values[key] = parser(match.group(1)) if match else None
    return RunInfo(path=path, **values)


def read_tmax_from_notes(experiment_dir: Path) -> int | None:
    notes = experiment_dir / "notes.md"
    if not notes.exists():
        return None
    text = notes.read_text(encoding="utf-8", errors="ignore")
    match = re.search(r"T_MAX\s*=\s*(\d+)", text)
    if match:
        return int(match.group(1))
    return None


def default_tmax(experiment_dir: Path, df: pd.DataFrame) -> int:
    noted = read_tmax_from_notes(experiment_dir)
    if noted is not None:
        return noted
    max_observed = int(df["t_relax"].max())
    if max_observed >= 25000:
        return max_observed
    return max_observed


def load_run(path: Path) -> pd.DataFrame:
    return pd.read_csv(
        path,
        sep=r"\s+",
        comment="#",
        names=COLUMNS,
        engine="python",
    )


def aggregate_grid(df: pd.DataFrame, tmax: int) -> pd.DataFrame:
    grouped = (
        df.assign(saturated=df["t_relax"] >= tmax)
        .groupby(["ix", "iy", "x1_0", "x2_0"], as_index=False)
        .agg(
            x1_mean=("x1_inf", "mean"),
            x2_mean=("x2_inf", "mean"),
            sigma1_mean=("sigma_1", "mean"),
            sigma2_mean=("sigma_2", "mean"),
            t_mean=("t_relax", "mean"),
            t_max=("t_relax", "max"),
            sat_frac=("saturated", "mean"),
            reps=("rep", "count"),
        )
    )
    grouped["t_frac"] = grouped["t_mean"] / tmax
    return grouped


def grid_matrix(agg: pd.DataFrame, column: str) -> np.ndarray:
    ndiv = int(max(agg["ix"].max(), agg["iy"].max()))
    matrix = np.full((ndiv + 1, ndiv + 1), np.nan)
    for row in agg.itertuples(index=False):
        matrix[int(row.iy), int(row.ix)] = getattr(row, column)
    return matrix


def title_for(info: RunInfo) -> str:
    return (
        f"N=({info.n1},{info.n2}), P11=P22={info.p11:g}, "
        f"P12={info.p12:g}, b={info.b:g}"
    )


def safe_stem(path: Path) -> str:
    return path.stem.replace("initial_plane__", "")


def draw_heat(ax: plt.Axes, matrix: np.ndarray, title: str, cmap: str, vmin: float, vmax: float):
    image = ax.imshow(
        matrix,
        origin="lower",
        extent=[0, 1, 0, 1],
        cmap=cmap,
        vmin=vmin,
        vmax=vmax,
        interpolation="nearest",
        aspect="equal",
    )
    ax.set_title(title, pad=8)
    ax.set_xlabel(r"$x_1(0)$")
    ax.set_ylabel(r"$x_2(0)$")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    return image


def plot_run_diagnostics(experiment_dir: Path, raw_path: Path, out_dir: Path) -> dict[str, object]:
    info = parse_run_info(raw_path)
    df = load_run(raw_path)
    tmax = default_tmax(experiment_dir, df)
    agg = aggregate_grid(df, tmax)

    x1 = grid_matrix(agg, "x1_mean")
    t_frac = grid_matrix(agg, "t_frac")
    sat = grid_matrix(agg, "sat_frac")

    fig, axes = plt.subplots(1, 3, figsize=(14.5, 4.6), constrained_layout=True)
    fig.suptitle(title_for(info), fontsize=14)

    im0 = draw_heat(axes[0], x1, r"$\langle x_1(\infty)\rangle$", "viridis", 0, 1)
    im1 = draw_heat(axes[1], t_frac, r"$\langle t_{relax}\rangle/T_{MAX}$", "YlOrRd", 0, 1)
    im2 = draw_heat(axes[2], sat, r"fraction at $T_{MAX}$", "Reds", 0, 1)

    saturated = agg[agg["sat_frac"] > 0]
    if not saturated.empty:
        axes[0].scatter(
            saturated["x1_0"],
            saturated["x2_0"],
            s=34,
            facecolors="none",
            edgecolors="#d7191c",
            linewidths=1.2,
            label=r"some reps at $T_{MAX}$",
        )
        axes[0].legend(frameon=False, loc="upper right", fontsize=8)

    for ax, image in zip(axes, (im0, im1, im2), strict=True):
        fig.colorbar(image, ax=ax, fraction=0.046, pad=0.04)

    out_path = out_dir / f"{safe_stem(raw_path)}__time_diagnostic.png"
    fig.savefig(out_path, dpi=220)
    plt.close(fig)

    return {
        "file": raw_path.name,
        "plot": out_path.name,
        "n1": info.n1,
        "n2": info.n2,
        "p11": info.p11,
        "p12": info.p12,
        "p22": info.p22,
        "b": info.b,
        "ndiv": info.ndiv,
        "reps": info.reps,
        "tmax": tmax,
        "mean_t_frac": float(agg["t_frac"].mean()),
        "max_t_frac": float(agg["t_frac"].max()),
        "mean_sat_frac": float(agg["sat_frac"].mean()),
        "max_sat_frac": float(agg["sat_frac"].max()),
        "points_with_any_saturation": int((agg["sat_frac"] > 0).sum()),
        "points": int(len(agg)),
    }


def read_summary(path: Path) -> pd.DataFrame:
    return pd.read_csv(path, sep="\t")


def write_summary(rows: list[dict[str, object]], out_path: Path) -> None:
    with out_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()), delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)


def plot_connectivity_summary(summary: pd.DataFrame, out_dir: Path) -> None:
    df = summary.dropna(subset=["p11"]).sort_values("p11")
    if df.empty:
        return
    fig, ax = plt.subplots(figsize=(7.4, 4.8), constrained_layout=True)
    ax.plot(df["p11"], df["mean_t_frac"], marker="o", lw=2.0, label=r"$\langle t\rangle/T_{MAX}$")
    ax.plot(df["p11"], df["mean_sat_frac"], marker="s", lw=2.0, label="mean saturated fraction")
    ax.plot(df["p11"], df["max_sat_frac"], marker="^", lw=1.8, label="max saturated fraction")
    ax.set_xlabel(r"$P_{11}=P_{22}$")
    ax.set_ylabel("time diagnostic")
    ax.set_ylim(-0.03, 1.03)
    ax.grid(True, alpha=0.35)
    ax.legend(frameon=False)
    fig.savefig(out_dir / "connectivity_time_summary.png", dpi=220)
    plt.close(fig)


def plot_scaling_summary(summary: pd.DataFrame, out_dir: Path, out_name: str, x_column: str) -> None:
    df = summary.copy()
    if x_column not in df:
        return
    fig, ax = plt.subplots(figsize=(8.0, 5.0), constrained_layout=True)
    for (p12, b), group in df.groupby(["p12", "b"], dropna=False):
        group = group.sort_values(x_column)
        label = rf"$P_{{12}}={p12:g}$, $b={b:g}$"
        ax.plot(group[x_column], group["mean_sat_frac"], marker="o", lw=2.0, label=label)
    ax.set_xlabel(x_column.replace("_", " "))
    ax.set_ylabel("mean saturated fraction")
    ax.set_ylim(-0.03, 1.03)
    ax.grid(True, alpha=0.35)
    ax.legend(frameon=False, fontsize=9)
    fig.savefig(out_dir / out_name, dpi=220)
    plt.close(fig)


def plot_asymmetry_summary(summary: pd.DataFrame, out_dir: Path) -> None:
    df = summary.copy()
    df["ratio"] = df["n1"] / df["n2"]
    df["label"] = df.apply(lambda row: f"{int(row.n1)}/{int(row.n2)}", axis=1)
    df = df.sort_values(["b", "p12", "ratio"])
    x = np.arange(len(df))

    fig, ax = plt.subplots(figsize=(11.0, 5.0), constrained_layout=True)
    colors = plt.cm.YlOrRd(np.clip(df["mean_t_frac"], 0, 1))
    ax.bar(x, df["mean_sat_frac"], color=colors, edgecolor="#333333", linewidth=0.5)
    ax.set_xticks(x)
    ax.set_xticklabels(
        [f"{row.label}\nP12={row.p12:g}\nb={row.b:g}" for row in df.itertuples()],
        rotation=0,
        fontsize=8,
    )
    ax.set_ylabel("mean saturated fraction")
    ax.set_ylim(0, 1)
    ax.grid(axis="y", alpha=0.35)
    sm = plt.cm.ScalarMappable(cmap="YlOrRd", norm=plt.Normalize(0, 1))
    sm.set_array([])
    fig.colorbar(sm, ax=ax, label=r"$\langle t_{relax}\rangle/T_{MAX}$")
    fig.savefig(out_dir / "highN_asymmetry_time_summary.png", dpi=220)
    plt.close(fig)


def process_experiment(experiment_dir: Path) -> None:
    raw_dir = experiment_dir / "raw"
    out_dir = experiment_dir / "diagnostics_time"
    out_dir.mkdir(parents=True, exist_ok=True)
    raw_files = sorted(raw_dir.glob("initial_plane__*.txt"))
    if not raw_files:
        print(f"No raw initial-plane files in {experiment_dir}")
        return

    rows = [plot_run_diagnostics(experiment_dir, path, out_dir) for path in raw_files]
    summary_path = out_dir / "time_summary.tsv"
    write_summary(rows, summary_path)
    summary = read_summary(summary_path)

    name = experiment_dir.name
    if "connectivity" in name:
        plot_connectivity_summary(summary, out_dir)
    elif "symmetric_N" in name:
        summary["ntot"] = summary["n1"] + summary["n2"]
        plot_scaling_summary(summary, out_dir, "symmetric_N_time_summary.png", "ntot")
    elif "highN" in name:
        plot_asymmetry_summary(summary, out_dir)

    print(f"{experiment_dir}: wrote {len(rows)} diagnostics to {out_dir}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Plot time-aware diagnostics for initial-plane scans.")
    parser.add_argument(
        "experiments",
        nargs="*",
        default=[
            "c_paper/out/experiments/2026-05-03_connectivity_scaling_N500",
            "c_paper/out/experiments/2026-05-03_symmetric_N_scaling",
            "c_paper/out/experiments/2026-05-03_highN_strong_asymmetry",
        ],
        help="Experiment directories containing raw/initial_plane__*.txt.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    for experiment in args.experiments:
        process_experiment(Path(experiment))


if __name__ == "__main__":
    main()
