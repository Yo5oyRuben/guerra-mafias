param(
  [string[]]$Experiments = @(
    '02_thermodynamic_limit_high_connectivity/connectivity_threshold',
    '02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling',
    '02_thermodynamic_limit_high_connectivity/finite_size_scaling/asymmetry/highN_asymmetry'
  )
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$ExperimentRoot = "$Base/out/experiments"
$PlotScript = "$Base/out/gp/plot_initial_plane.gp"

function Get-TMax([System.IO.FileInfo]$File) {
  $header = Get-Content -LiteralPath $File.FullName -TotalCount 40
  $line = $header | Where-Object { $_ -match '^\s*#\s+T_MAX\s+(\S+)' } | Select-Object -First 1
  if ($line -and $line -match '^\s*#\s+T_MAX\s+(\S+)') { return $matches[1] }

  if ($File.Name -match '__TMAX_([^_]+)__') {
    return (($matches[1] -replace 'm','-') -replace 'p','.')
  }

  return ''
}

foreach ($experiment in $Experiments) {
  $root = Join-Path $ExperimentRoot $experiment
  $raw = Join-Path $root 'raw'
  $plots = Join-Path $root 'plots'

  if (!(Test-Path -LiteralPath $raw)) {
    Write-Warning "No existe raw/: $raw"
    continue
  }

  New-Item -ItemType Directory -Force -Path $plots | Out-Null
  Get-ChildItem -LiteralPath $plots -File |
    Where-Object {
      $_.Name -match '^initial_plane_\d{3}\.png$' -or
      $_.Name -match '^ip\d{3}.*\.png$' -or
      $_.Name -eq '_gnuplot_tmp_initial_plane.png'
    } |
    Remove-Item -Force

  $files = Get-ChildItem -LiteralPath $raw -Filter 'initial_plane__*.txt' | Sort-Object Name
  Write-Host "Regenerando $($files.Count) plots en $root"
  $manifest = Join-Path $plots 'initial_plane_time_plots.tsv'
  "plot`tdata`tT_MAX" | Set-Content -Encoding ASCII -LiteralPath $manifest

  foreach ($file in $files) {
    $outfile = Join-Path $plots ([IO.Path]::GetFileNameWithoutExtension($file.Name) + '.png')
    $tmpOut = Join-Path $plots '_gnuplot_tmp_initial_plane.png'
    $inForGnuplot = (Resolve-Path -LiteralPath $file.FullName -Relative).Replace('.\','').Replace('\','/')
    $outForGnuplot = $tmpOut.Replace('\','/')
    $tmax = Get-TMax $file
    if ($tmax -ne '') {
      & gnuplot -e "tmax=$tmax; infile='$inForGnuplot'; outfile='$outForGnuplot'" $PlotScript
    } else {
      & gnuplot -e "infile='$inForGnuplot'; outfile='$outForGnuplot'" $PlotScript
    }
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo gnuplot para $($file.FullName)"
    }
    Move-Item -LiteralPath $tmpOut -Destination $outfile -Force
    "$outfile`t$($file.FullName)`t$tmax" | Add-Content -Encoding ASCII -LiteralPath $manifest
  }
}
