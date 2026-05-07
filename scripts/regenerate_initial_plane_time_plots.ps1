param(
  [string[]]$Experiments = @(
    '2026-05-03_connectivity_scaling_N500',
    '2026-05-03_symmetric_N_scaling',
    '2026-05-03_highN_strong_asymmetry'
  )
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$ExperimentRoot = "$Base/out/experiments"
$PlotScript = "$Base/out/gp/plot_initial_plane.gp"

function Get-TMax([string]$Experiment) {
  if ($Experiment -eq '2026-05-03_symmetric_N_scaling') { return 30000 }
  return 25000
}

foreach ($experiment in $Experiments) {
  $root = Join-Path $ExperimentRoot $experiment
  $raw = Join-Path $root 'raw'
  $plots = Join-Path $root 'plots'
  $tmax = Get-TMax $experiment

  if (!(Test-Path -LiteralPath $raw)) {
    Write-Warning "No existe raw/: $raw"
    continue
  }

  New-Item -ItemType Directory -Force -Path $plots | Out-Null
  $files = Get-ChildItem -LiteralPath $raw -Filter 'initial_plane__*.txt' | Sort-Object Name
  Write-Host "Regenerando $($files.Count) plots en $root con T_MAX=$tmax"

  foreach ($file in $files) {
    $outfile = Join-Path $plots ([IO.Path]::GetFileNameWithoutExtension($file.Name) + '.png')
    & gnuplot -e "tmax=$tmax; infile='$($file.FullName.Replace('\','/'))'; outfile='$($outfile.Replace('\','/'))'" $PlotScript
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo gnuplot para $($file.FullName)"
    }
  }
}
