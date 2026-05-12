from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


ROOT = Path("c_paper/out/experiments")
CATALOG = ROOT / "experiment_catalog.tsv"
README = ROOT / "README.md"


@dataclass(frozen=True)
class Category:
    name: str
    purpose: str


CATEGORY_PURPOSES = {
    "active_or_incomplete": "Runs launched recently, aborted controllers, or outputs that should not be moved while work is still active.",
    "paper_baseline_sweep_b": "Baseline sweep_b reproductions of paper-style figures with the original linear update.",
    "fermi_sweep_b": "Sweep_b experiments comparing Fermi copy probability across beta and p12.",
    "degree_linear_sweep_b": "Sweep_b experiments using the degree-weighted linear copy probability.",
    "thermodynamic_limit_high_connectivity": "Initial-plane checks of analytic fixed points in large-N / high-connectivity regimes.",
    "connectivity_and_scaling": "Initial-plane scans designed to locate connectivity thresholds and finite-size scaling.",
    "critical_relaxation": "Long T_MAX experiments focused on relaxation time and critical slowing down.",
    "frontier_scans_torre": "Grid/refinement experiments from the tower machine around the transition frontier.",
    "asymmetry_and_lowN": "Asymmetry, low-N, and high-N-asymmetric initial-plane checks.",
    "scratch_or_smoke": "Small tests, smoke runs, launch checks, and temporary folders.",
    "plot_collections": "Folders that mostly collect derived plots rather than primary raw runs.",
    "uncategorized": "Needs manual review.",
}


ACTIVE_NAMES = {
    "degree_linear_overnight_fig3_thermo_2026-05-11_real",
}


def classify(name: str) -> tuple[str, str]:
    lower = name.lower()

    if name in ACTIVE_NAMES or lower.endswith("_00-12-24") or lower.endswith("_00-16-10"):
        return "active_or_incomplete", "current degree-linear thermodynamic-limit work; keep in place"
    if lower == "fig3_degree_alpha1":
        return "degree_linear_sweep_b", "interrupted degree-linear Fig. 3 sweep attempt"
    if lower.startswith("_") or "smoke" in lower or "launch_test" in lower:
        return "scratch_or_smoke", "test or launcher validation, useful only for provenance/debugging"
    if lower == "sweep_b_2026-05-04_escalated_parallel_independent":
        return "paper_baseline_sweep_b", "paper Fig. 3/Fig. 4 baseline plus stronger-coupling Fig. 4"
    if lower.startswith("sweep_b_fig4_fermi") or lower.startswith("sweep_b_fig3_fermi"):
        return "fermi_sweep_b", "Fermi copy probability sweep_b comparison"
    if lower.startswith("fig4_degree") or lower.startswith("degree_linear_overnight"):
        return "degree_linear_sweep_b", "degree-weighted linear probability sweep_b or interrupted Fig. 3 attempt"
    if "fermi_thermodynamic_limit" in lower:
        return "thermodynamic_limit", "Fermi large-N/high-connectivity initial-plane checks"
    if "connectivity_scaling" in lower or "symmetric_n_scaling" in lower:
        return "connectivity_and_scaling", "connectivity threshold and N-scaling maps"
    if "relaxation" in lower:
        return "critical_relaxation", "critical relaxation-time and T_MAX sensitivity maps"
    if lower.startswith("torre_"):
        return "frontier_scans_torre", "transition-frontier scans run on the tower machine"
    if "asymmetry" in lower or "lown" in lower or "highn" in lower:
        return "asymmetry_and_lowN", "finite-size/asymmetry exploration"
    if "comparison" in lower and "raw" not in lower:
        return "plot_collections", "derived comparison plots"

    return "uncategorized", "manual classification needed"


def count_files(path: Path, subdir: str, pattern: str) -> int:
    target = path / subdir
    if not target.exists():
        return 0
    return sum(1 for _ in target.glob(pattern))


def has_file(path: Path, name: str) -> bool:
    return (path / name).exists()


def main() -> None:
    rows = []
    candidates = [
        p
        for p in ROOT.rglob("*")
        if p.is_dir()
        and (
            (p / "raw").exists()
            or (p / "plots").exists()
            or (p / "logs").exists()
            or (p / "manifest.tsv").exists()
            or (p / "notes.md").exists()
        )
    ]
    for exp in sorted(candidates, key=lambda p: str(p.relative_to(ROOT)).lower()):
        category, note = classify(exp.name)
        relative_path = exp.relative_to(ROOT).as_posix()
        if relative_path == "01_paper_baselines":
            category = "paper_baseline_sweep_b"
            note = "paper Fig. 3/Fig. 4 baseline plus stronger-coupling Fig. 4"
        if relative_path.startswith("02_thermodynamic_limit_high_connectivity/"):
            category = "thermodynamic_limit_high_connectivity"
            note = "large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior"
        if relative_path.startswith("03_critical_transition/frontier_scans_torre/"):
            category = "frontier_scans_torre"
            note = "transition-frontier scan around the critical region"
        if relative_path.startswith("03_critical_transition/relaxation_time/statistics"):
            category = "critical_relaxation"
            note = "relaxation-time statistics near the critical region"
        if relative_path.startswith("03_critical_transition/relaxation_time/tmax_ladder"):
            category = "critical_relaxation"
            note = "T_MAX ladder for critical slowing-down diagnostics"
        if relative_path.startswith("04_copy_probability/degree_linear"):
            category = "degree_linear_sweep_b"
            note = "degree-weighted linear probability sweep_b"
        if relative_path.startswith("04_copy_probability/fermi/sweep_b_fig3"):
            category = "fermi_sweep_b"
            note = "Fermi copy probability Fig. 3 sweep_b"
        if relative_path.startswith("04_copy_probability/fermi/derived_comparisons"):
            category = "fermi_sweep_b"
            note = "derived Fermi comparison plots"
        rows.append(
            {
                "category": category,
                "experiment": exp.name,
                "path": relative_path,
                "status": "active_do_not_move" if any(part in ACTIVE_NAMES for part in exp.relative_to(ROOT).parts) else "archived_or_completed",
                "raw_files": count_files(exp, "raw", "*"),
                "plot_files": count_files(exp, "plots", "*"),
                "log_files": count_files(exp, "logs", "*"),
                "has_manifest": "yes" if has_file(exp, "manifest.tsv") else "no",
                "has_notes": "yes" if has_file(exp, "notes.md") else "no",
                "last_write": exp.stat().st_mtime,
                "note": note,
            }
        )

    CATALOG.write_text(
        "\t".join(
            [
                "category",
                "experiment",
                "path",
                "status",
                "raw_files",
                "plot_files",
                "log_files",
                "has_manifest",
                "has_notes",
                "note",
            ]
        )
        + "\n"
        + "\n".join(
            "\t".join(
                [
                    row["category"],
                    row["experiment"],
                    row["path"],
                    row["status"],
                    str(row["raw_files"]),
                    str(row["plot_files"]),
                    str(row["log_files"]),
                    row["has_manifest"],
                    row["has_notes"],
                    row["note"],
                ]
            )
            for row in rows
        )
        + "\n",
        encoding="utf-8",
    )

    by_category: dict[str, list[dict[str, object]]] = {}
    for row in rows:
        by_category.setdefault(str(row["category"]), []).append(row)

    lines = [
        "# Experiment Organization",
        "",
        "This index organizes existing experiment folders by scientific purpose without moving any experiment data.",
        "",
        "Important: folders marked `active_do_not_move` are linked to work currently running or recently interrupted and should stay in place until the current simulations are fully curated.",
        "",
        "Primary table: `experiment_catalog.tsv`.",
        "",
        "## Categories",
        "",
    ]

    for category in sorted(by_category):
        lines.append(f"### {category}")
        lines.append("")
        lines.append(CATEGORY_PURPOSES.get(category, CATEGORY_PURPOSES["uncategorized"]))
        lines.append("")
        for row in by_category[category]:
            bits = [
                f"`{row['experiment']}`",
                f"path=`{row['path']}`",
                f"status={row['status']}",
                f"raw={row['raw_files']}",
                f"plots={row['plot_files']}",
            ]
            if row["has_notes"] == "yes":
                bits.append("notes=yes")
            if row["has_manifest"] == "yes":
                bits.append("manifest=yes")
            lines.append("- " + "; ".join(bits))
            lines.append(f"  Purpose: {row['note']}")
        lines.append("")

    lines.extend(
        [
            "## Proposed Physical Layout",
            "",
            "For now this is only a proposal. Moving folders can be done later once active runs finish.",
            "",
            "- `00_active_or_incomplete/`: active controllers, interrupted runs, launch artefacts worth keeping temporarily.",
            "- `01_paper_baselines/`: original linear-probability paper reproductions.",
            "- `01_paper_baselines/`: original linear-probability sweep_b reproductions.",
            "- `02_thermodynamic_limit_high_connectivity/`: thermodynamic-limit, high-connectivity, N-scaling, and asymmetry checks.",
            "- `03_critical_transition/`: T_MAX, critical slowing down, and frontier scans.",
            "- `04_copy_probability/`: Fermi and degree-weighted linear update-rule comparisons.",
            "- `99_scratch_smoke/`: smoke tests and temporary launch checks.",
            "",
            "## Plotting Notes",
            "",
            "Most initial-plane `.txt` files include final states, sigmas, and `t_relax`; plots should expose both final attractor and relaxation time. Sweep-b `.tsv` files include mean and SEM for `x1`, `x2`, and global cooperation, so regenerated figures can show uncertainty bands and compare rules directly.",
        ]
    )

    README.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {CATALOG}")
    print(f"Wrote {README}")


if __name__ == "__main__":
    main()
