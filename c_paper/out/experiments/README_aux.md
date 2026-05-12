# Experiment Organization

This index organizes existing experiment folders by scientific purpose without moving any experiment data.

Important: folders marked `active_do_not_move` are linked to work currently running or recently interrupted and should stay in place until the current simulations are fully curated.

Primary table: `experiment_catalog.tsv`.

## Categories

### active_or_incomplete

Runs launched recently, aborted controllers, or outputs that should not be moved while work is still active.

- `degree_linear_overnight_fig3_thermo_2026-05-11_real`; path=`degree_linear_overnight_fig3_thermo_2026-05-11_real`; status=active_do_not_move; raw=0; plots=2
  Purpose: current degree-linear thermodynamic-limit work; keep in place

### critical_relaxation

Long T_MAX experiments focused on relaxation time and critical slowing down.

- `2026-05-06_relaxation_p073_TMAX200k`; path=`03_critical_transition/relaxation_time/p073_single/2026-05-06_relaxation_p073_TMAX200k`; status=archived_or_completed; raw=2; plots=2; notes=yes; manifest=yes
  Purpose: critical relaxation-time and T_MAX sensitivity maps
- `2026-05-06_relaxation_p073_TMAX400k`; path=`03_critical_transition/relaxation_time/p073_single/2026-05-06_relaxation_p073_TMAX400k`; status=archived_or_completed; raw=2; plots=2; notes=yes; manifest=yes
  Purpose: critical relaxation-time and T_MAX sensitivity maps
- `2026-05-06_relaxation_critical_TMAX400k_p_fine`; path=`03_critical_transition/relaxation_time/p_fine/2026-05-06_relaxation_critical_TMAX400k_p_fine`; status=archived_or_completed; raw=7; plots=7; notes=yes; manifest=yes
  Purpose: critical relaxation-time and T_MAX sensitivity maps
- `2026-05-07_relaxation_critical_p_narrow_TMAX400k`; path=`03_critical_transition/relaxation_time/p_fine/2026-05-07_relaxation_critical_p_narrow_TMAX400k`; status=archived_or_completed; raw=5; plots=5; notes=yes; manifest=yes
  Purpose: critical relaxation-time and T_MAX sensitivity maps
- `statistics`; path=`03_critical_transition/relaxation_time/statistics`; status=archived_or_completed; raw=2; plots=2; notes=yes; manifest=yes
  Purpose: relaxation-time statistics near the critical region
- `tmax_ladder`; path=`03_critical_transition/relaxation_time/tmax_ladder`; status=archived_or_completed; raw=9; plots=9; notes=yes; manifest=yes
  Purpose: T_MAX ladder for critical slowing-down diagnostics

### degree_linear_sweep_b

Sweep_b experiments using the degree-weighted linear copy probability.

- `degree_linear`; path=`04_copy_probability/degree_linear`; status=archived_or_completed; raw=12; plots=9; notes=yes; manifest=yes
  Purpose: degree-weighted linear probability sweep_b
- `fig3_degree_alpha1`; path=`degree_linear_overnight_fig3_thermo_2026-05-11_real/fig3_degree_alpha1`; status=active_do_not_move; raw=7; plots=0; manifest=yes
  Purpose: interrupted degree-linear Fig. 3 sweep attempt

### fermi_sweep_b

Sweep_b experiments comparing Fermi copy probability across beta and p12.

- `derived_comparisons`; path=`04_copy_probability/fermi/derived_comparisons`; status=archived_or_completed; raw=0; plots=7
  Purpose: derived Fermi comparison plots
- `sweep_b_fig3`; path=`04_copy_probability/fermi/sweep_b_fig3`; status=archived_or_completed; raw=5; plots=0; manifest=yes
  Purpose: Fermi copy probability Fig. 3 sweep_b
- `sweep_b_fig3_tower_2026-05-10`; path=`04_copy_probability/fermi/sweep_b_fig3/tower_2026-05-10`; status=archived_or_completed; raw=4; plots=4; manifest=yes
  Purpose: Tower run for Fermi beta=5 Fig. 3 sweep_b
- `sweep_b_fig4_fermi_beta_10_full_2026-05-07`; path=`04_copy_probability/fermi/sweep_b_fig4/sweep_b_fig4_fermi_beta_10_full_2026-05-07`; status=archived_or_completed; raw=8; plots=3; manifest=yes
  Purpose: Fermi copy probability sweep_b comparison
- `sweep_b_fig4_fermi_beta_1_full_2026-05-07`; path=`04_copy_probability/fermi/sweep_b_fig4/sweep_b_fig4_fermi_beta_1_full_2026-05-07`; status=archived_or_completed; raw=8; plots=3; manifest=yes
  Purpose: Fermi copy probability sweep_b comparison
- `sweep_b_fig4_fermi_beta_5_full_2026-05-07_run2`; path=`04_copy_probability/fermi/sweep_b_fig4/sweep_b_fig4_fermi_beta_5_full_2026-05-07_run2`; status=archived_or_completed; raw=8; plots=3; manifest=yes
  Purpose: Fermi copy probability sweep_b comparison

### frontier_scans_torre

Grid/refinement experiments from the tower machine around the transition frontier.

- `b_scan`; path=`03_critical_transition/frontier_scans_torre/b_scan`; status=archived_or_completed; raw=13; plots=5; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `boundary_robustness`; path=`03_critical_transition/frontier_scans_torre/boundary_robustness`; status=archived_or_completed; raw=13; plots=5; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `followup`; path=`03_critical_transition/frontier_scans_torre/followup`; status=archived_or_completed; raw=19; plots=7; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `high_p11_frontier`; path=`03_critical_transition/frontier_scans_torre/high_p11_frontier`; status=archived_or_completed; raw=37; plots=13; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `p11_p12_grid`; path=`03_critical_transition/frontier_scans_torre/p11_p12_grid`; status=archived_or_completed; raw=46; plots=16; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `p11_p12_refine`; path=`03_critical_transition/frontier_scans_torre/p11_p12_refine`; status=archived_or_completed; raw=37; plots=13; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region
- `p12_scan`; path=`03_critical_transition/frontier_scans_torre/p12_scan`; status=archived_or_completed; raw=19; plots=7; notes=yes; manifest=yes
  Purpose: transition-frontier scan around the critical region

### paper_baseline_sweep_b

Baseline sweep_b reproductions of paper-style figures with the original linear update.

- `01_paper_baselines`; path=`01_paper_baselines`; status=archived_or_completed; raw=20; plots=9; manifest=yes
  Purpose: paper Fig. 3/Fig. 4 baseline plus stronger-coupling Fig. 4

### thermodynamic_limit_high_connectivity

Initial-plane checks of analytic fixed points in large-N / high-connectivity regimes.

- `critical_asymmetry`; path=`02_thermodynamic_limit_high_connectivity/asymmetry/critical_asymmetry`; status=archived_or_completed; raw=3; plots=3; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `highN_asymmetry`; path=`02_thermodynamic_limit_high_connectivity/asymmetry/highN_asymmetry`; status=archived_or_completed; raw=13; plots=13; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `lowN_asymmetry`; path=`02_thermodynamic_limit_high_connectivity/asymmetry/lowN_asymmetry`; status=archived_or_completed; raw=13; plots=13; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `connectivity_threshold`; path=`02_thermodynamic_limit_high_connectivity/connectivity_threshold`; status=archived_or_completed; raw=21; plots=18; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `fermi`; path=`02_thermodynamic_limit_high_connectivity/fermi`; status=archived_or_completed; raw=5; plots=5; notes=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `n_scaling_critical`; path=`02_thermodynamic_limit_high_connectivity/finite_size_scaling/n_scaling_critical`; status=archived_or_completed; raw=4; plots=4; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior
- `symmetric_N_scaling`; path=`02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling`; status=archived_or_completed; raw=13; plots=13; notes=yes; manifest=yes
  Purpose: large-N, connectivity, finite-size, or asymmetry check against thermodynamic-limit behavior

## Proposed Physical Layout

For now this is only a proposal. Moving folders can be done later once active runs finish.

- `00_active_or_incomplete/`: active controllers, interrupted runs, launch artefacts worth keeping temporarily.
- `01_paper_baselines/`: original linear-probability paper reproductions.
- `01_paper_baselines/`: original linear-probability sweep_b reproductions.
- `02_thermodynamic_limit_high_connectivity/`: thermodynamic-limit, high-connectivity, N-scaling, and asymmetry checks.
- `03_critical_transition/`: T_MAX, critical slowing down, and frontier scans.
- `04_copy_probability/`: Fermi and degree-weighted linear update-rule comparisons.
- `99_scratch_smoke/`: smoke tests and temporary launch checks.

## Plotting Notes

Most initial-plane `.txt` files include final states, sigmas, and `t_relax`; plots should expose both final attractor and relaxation time. Sweep-b `.tsv` files include mean and SEM for `x1`, `x2`, and global cooperation, so regenerated figures can show uncertainty bands and compare rules directly.
