param(
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$Root = Resolve-Path 'c_paper/out/experiments'
$RootPath = [System.IO.Path]::GetFullPath($Root.Path)

function Assert-UnderRoot {
  param([string]$Path)
  $full = [System.IO.Path]::GetFullPath($Path)
  if (-not $full.StartsWith($RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ruta fuera de experiments: $full"
  }
  return $full
}

function Add-Move {
  param(
    [System.Collections.ArrayList]$Moves,
    [string]$Name,
    [string]$DestSubdir
  )
  [void]$Moves.Add([pscustomobject]@{
    Name = $Name
    Source = Join-Path $RootPath $Name
    Destination = Join-Path (Join-Path $RootPath $DestSubdir) $Name
  })
}

$moves = [System.Collections.ArrayList]::new()

# Paper reference and original linear update.
Add-Move $moves 'sweep_b_2026-05-04_escalated_parallel_independent' '01_paper_baselines/sweep_b_linear_original'

# Copy-probability variants.
Add-Move $moves 'sweep_b_fig3_fermi_beta_5_2026-05-09' '02_copy_probability/fermi/sweep_b_fig3'
Add-Move $moves 'sweep_b_fig4_fermi_beta_1_full_2026-05-07' '02_copy_probability/fermi/sweep_b_fig4'
Add-Move $moves 'sweep_b_fig4_fermi_beta_5_full_2026-05-07_run2' '02_copy_probability/fermi/sweep_b_fig4'
Add-Move $moves 'sweep_b_fig4_fermi_beta_10_full_2026-05-07' '02_copy_probability/fermi/sweep_b_fig4'
Add-Move $moves 'sweep_b_fig4_fermi_comparison_2026-05-09' '02_copy_probability/fermi/derived_comparisons'
Add-Move $moves 'fig4_degree_linear_alpha1_and_alpha_sweep_2026-05-10' '02_copy_probability/degree_linear/sweep_b_fig4'

# Thermodynamic-limit checks.
Add-Move $moves '2026-05-10_fermi_thermodynamic_limit' '03_thermodynamic_limit/fermi'

# Critical point, relaxation-time, and frontier scans.
Add-Move $moves '2026-05-05_relaxation_ladder_TMAX50k_100k' '04_critical_transition/relaxation_time/tmax_ladder'
Add-Move $moves '2026-05-06_relaxation_p073_TMAX200k' '04_critical_transition/relaxation_time/p073_single'
Add-Move $moves '2026-05-06_relaxation_p073_TMAX400k' '04_critical_transition/relaxation_time/p073_single'
Add-Move $moves '2026-05-06_relaxation_critical_TMAX400k_p_fine' '04_critical_transition/relaxation_time/p_fine'
Add-Move $moves '2026-05-07_relaxation_critical_p_narrow_TMAX400k' '04_critical_transition/relaxation_time/p_fine'
Add-Move $moves '2026-05-06_relaxation_critical_TMAX400k_n_scaling' '04_critical_transition/relaxation_time/n_scaling'
Add-Move $moves '2026-05-06_relaxation_critical_TMAX400k_asym' '04_critical_transition/relaxation_time/asymmetry'
Add-Move $moves '2026-05-06_relaxation_critical_TMAX400k_stats_reps10' '04_critical_transition/relaxation_time/statistics'

Add-Move $moves 'torre_2026-05-07_b_scan_TMAX400k' '04_critical_transition/frontier_scans_torre/b_scan'
Add-Move $moves 'torre_2026-05-07_p12_scan_TMAX400k' '04_critical_transition/frontier_scans_torre/p12_scan'
Add-Move $moves 'torre_2026-05-07_p11_p12_grid_TMAX400k' '04_critical_transition/frontier_scans_torre/p11_p12_grid'
Add-Move $moves 'torre_2026-05-08_p11_p12_refine_TMAX400k' '04_critical_transition/frontier_scans_torre/p11_p12_refine'
Add-Move $moves 'torre_2026-05-08_high_p11_frontier_TMAX400k' '04_critical_transition/frontier_scans_torre/high_p11_frontier'
Add-Move $moves 'torre_2026-05-08_boundary_robust_TMAX400k' '04_critical_transition/frontier_scans_torre/boundary_robustness'
Add-Move $moves 'torre_2026-05-09_frontier_followup_TMAX400k' '04_critical_transition/frontier_scans_torre/followup'

# Connectivity, finite size, and asymmetry away from the critical-frontier campaign.
Add-Move $moves '2026-05-03_connectivity_scaling_N500' '05_connectivity_finite_size/connectivity_threshold'
Add-Move $moves '2026-05-03_symmetric_N_scaling' '05_connectivity_finite_size/symmetric_N_scaling'
Add-Move $moves '2026-05-03_lowN_asymmetry_corrected' '05_connectivity_finite_size/lowN_asymmetry'
Add-Move $moves '2026-05-03_highN_strong_asymmetry' '05_connectivity_finite_size/highN_asymmetry'

# Scratch, smoke tests, and failed launch wrappers. The active real run is intentionally not moved.
Add-Move $moves '_smoke_fig3_degree_launch_check_2026-05-11' '99_scratch_smoke/degree_linear'
Add-Move $moves '_smoke_master_degree_2026-05-11' '99_scratch_smoke/degree_linear'
Add-Move $moves '_tmp_fig3_fermi_launch_test' '99_scratch_smoke/fermi'
Add-Move $moves 'smoke_fig4_degree_linear_2026-05-10' '99_scratch_smoke/degree_linear'
Add-Move $moves 'degree_linear_overnight_fig3_thermo_2026-05-11_00-12-24' '99_scratch_smoke/degree_linear_failed_launches'
Add-Move $moves 'degree_linear_overnight_fig3_thermo_2026-05-11_00-16-10' '99_scratch_smoke/degree_linear_failed_launches'

$active = 'degree_linear_overnight_fig3_thermo_2026-05-11_real'

foreach ($move in $moves) {
  $src = Assert-UnderRoot $move.Source
  $dst = Assert-UnderRoot $move.Destination
  if ($move.Name -eq $active) {
    throw "Intento de mover carpeta activa: $active"
  }
  if (-not (Test-Path -LiteralPath $src)) {
    Write-Host "SKIP missing: $($move.Name)"
    continue
  }
  if (Test-Path -LiteralPath $dst) {
    Write-Host "SKIP exists: $($move.Name) -> $dst"
    continue
  }

  Write-Host ("{0} -> {1}" -f $move.Name, ($dst.Substring($RootPath.Length + 1)))
  if ($Apply) {
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($dst)) | Out-Null
    Move-Item -LiteralPath $src -Destination $dst
  }
}

if ($Apply) {
  $readme = @"
# Organized Experiment Layout

This directory is now organized by scientific purpose. The current active run is intentionally left at the root:

- `degree_linear_overnight_fig3_thermo_2026-05-11_real`

Main groups:

- `01_paper_baselines/`: original linear-probability sweep_b reproductions.
- `02_copy_probability/`: Fermi and degree-linear update-rule comparisons.
- `03_thermodynamic_limit/`: large-N, connectivity threshold, N scaling, and asymmetry checks against analytic fixed points.
- `04_critical_transition/`: critical relaxation, p/frontier scans, and tower-machine refinements.
- `99_scratch_smoke/`: smoke tests, temporary launch checks, and failed wrapper attempts.

No raw global files in `c_paper/out/raw` were moved. Active simulations should be curated into one of these groups only after they finish.
"@
  $readme | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $RootPath 'ORGANIZED_LAYOUT.md')
}
