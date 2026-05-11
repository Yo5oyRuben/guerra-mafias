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
    [string]$From,
    [string]$To
  )
  [void]$Moves.Add([pscustomobject]@{
    Source = Join-Path $RootPath $From
    Destination = Join-Path $RootPath $To
  })
}

$moves = [System.Collections.ArrayList]::new()

Add-Move $moves `
  '04_critical_transition/relaxation_time/n_scaling/2026-05-06_relaxation_critical_TMAX400k_n_scaling' `
  '03_thermodynamic_limit/finite_size_scaling/n_scaling_critical/2026-05-06_relaxation_critical_TMAX400k_n_scaling'

Add-Move $moves `
  '04_critical_transition/relaxation_time/asymmetry/2026-05-06_relaxation_critical_TMAX400k_asym' `
  '03_thermodynamic_limit/asymmetry/critical_asymmetry/2026-05-06_relaxation_critical_TMAX400k_asym'

Add-Move $moves `
  '05_connectivity_finite_size/connectivity_threshold/2026-05-03_connectivity_scaling_N500' `
  '03_thermodynamic_limit/connectivity_threshold/2026-05-03_connectivity_scaling_N500'

Add-Move $moves `
  '05_connectivity_finite_size/symmetric_N_scaling/2026-05-03_symmetric_N_scaling' `
  '03_thermodynamic_limit/finite_size_scaling/symmetric_N_scaling/2026-05-03_symmetric_N_scaling'

Add-Move $moves `
  '05_connectivity_finite_size/lowN_asymmetry/2026-05-03_lowN_asymmetry_corrected' `
  '03_thermodynamic_limit/asymmetry/lowN_asymmetry/2026-05-03_lowN_asymmetry_corrected'

Add-Move $moves `
  '05_connectivity_finite_size/highN_asymmetry/2026-05-03_highN_strong_asymmetry' `
  '03_thermodynamic_limit/asymmetry/highN_asymmetry/2026-05-03_highN_strong_asymmetry'

foreach ($move in $moves) {
  $src = Assert-UnderRoot $move.Source
  $dst = Assert-UnderRoot $move.Destination

  if (-not (Test-Path -LiteralPath $src)) {
    Write-Host "SKIP missing: $($src.Substring($RootPath.Length + 1))"
    continue
  }
  if (Test-Path -LiteralPath $dst) {
    Write-Host "SKIP exists: $($dst.Substring($RootPath.Length + 1))"
    continue
  }

  Write-Host ("{0} -> {1}" -f ($src.Substring($RootPath.Length + 1)), ($dst.Substring($RootPath.Length + 1)))
  if ($Apply) {
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($dst)) | Out-Null
    Move-Item -LiteralPath $src -Destination $dst
  }
}

if ($Apply) {
  foreach ($dir in @(
    '05_connectivity_finite_size/connectivity_threshold',
    '05_connectivity_finite_size/symmetric_N_scaling',
    '05_connectivity_finite_size/lowN_asymmetry',
    '05_connectivity_finite_size/highN_asymmetry',
    '05_connectivity_finite_size',
    '04_critical_transition/relaxation_time/n_scaling',
    '04_critical_transition/relaxation_time/asymmetry'
  )) {
    $path = Assert-UnderRoot (Join-Path $RootPath $dir)
    if ((Test-Path -LiteralPath $path) -and -not (Get-ChildItem -LiteralPath $path -Force)) {
      Remove-Item -LiteralPath $path
      Write-Host "Removed empty: $dir"
    }
  }
}
