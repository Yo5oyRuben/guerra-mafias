param(
  [int]$Jobs = 12,
  [int]$NDiv = 8,
  [int]$NReps = 3,
  [string]$Experiment = '2026-05-07_relaxation_critical_p_narrow_TMAX400k'
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$LogDir = "$Base/out/logs"

function Get-NewManifest([string]$Preset, [hashtable]$Before) {
  $manifest = Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" |
    Where-Object { -not $Before.ContainsKey($_.FullName) } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $manifest) {
    $manifest = Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
  }

  if (-not $manifest) {
    throw "No encuentro el manifest para $Preset despues de la ejecucion."
  }

  return $manifest
}

function Get-TmaxFromPath([string]$Path) {
  $m = [regex]::Match($Path, 'TMAX_(\d+)')
  if ($m.Success) { return [int]$m.Groups[1].Value }
  return 400000
}

function Safe-PlotToken([string]$Value) {
  return (($Value.Trim() -replace '\.', 'p') -replace '-', 'm')
}

function New-GnuplotPlots([string]$Experiment, [string]$Manifest) {
  $root = "$Base/out/experiments/$Experiment"
  $plots = "$root/plots"
  New-Item -ItemType Directory -Force -Path $plots | Out-Null

  $gnuplot = Get-Command gnuplot -ErrorAction SilentlyContinue
  if (-not $gnuplot) {
    Write-Warning 'gnuplot no esta en PATH; salto las graficas gnuplot.'
    return
  }

  $rows = Import-Csv -Delimiter "`t" -LiteralPath $Manifest
  foreach ($row in $rows) {
    $rawName = [IO.Path]::GetFileName($row.output)
    $rawPath = Join-Path "$root/raw" $rawName
    if (-not (Test-Path -LiteralPath $rawPath)) {
      Write-Warning "No existe raw curado para plot: $rawPath"
      continue
    }

    $tmax = Get-TmaxFromPath $rawName
    $p = Safe-PlotToken $row.P11
    $outfile = Join-Path $plots ("plot_{0:D2}_P_{1}_TMAX_{2}_reps_{3}.png" -f [int]$row.index,$p,$tmax,$row.reps)

    & gnuplot -e "tmax=$tmax; infile='$($rawPath.Replace('\','/'))'; outfile='$($outfile.Replace('\','/'))'" "$Base/out/gp/plot_initial_plane.gp"
    if ($LASTEXITCODE -ne 0) {
      throw "Fallo gnuplot para $rawPath"
    }
  }
}

function New-TimeDiagnostics([string]$Experiment) {
  $root = "$Base/out/experiments/$Experiment"
  $python = '.venv/Scripts/python.exe'
  if (-not (Test-Path -LiteralPath $python)) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $cmd) {
      Write-Warning 'No encuentro python; salto diagnostics_time.'
      return
    }
    $python = $cmd.Source
  }

  & $python py/plot_initial_plane_time_diagnostics.py $root
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo diagnostics_time para $Experiment"
  }
}

$Preset = 'relaxationCriticalPNarrowT400k'
New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
$before = @{}
Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" -ErrorAction SilentlyContinue |
  ForEach-Object { $before[$_.FullName] = $true }

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
  -Preset $Preset -Jobs $Jobs -NDiv $NDiv -NReps $NReps -NoPlot

if ($LASTEXITCODE -ne 0) {
  throw "La cola $Preset fallo con codigo $LASTEXITCODE"
}

$manifest = Get-NewManifest $Preset $before

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/curate_initial_plane_experiment.ps1 `
  -Manifest $manifest.FullName `
  -Experiment $Experiment `
  -Title 'Relaxation critical narrow connectivity scan TMAX=400000' `
  -Question 'Resolver la ventana estrecha de transicion entre P11=P22=0.715 y 0.745, donde aparece bruscamente la cuenca del punto fijo interior.' `
  -Notes 'N1=N2=500, P12=0.20, b=1.15, R=0, E=-0.4. Valores P11=P22=0.720, 0.725, 0.735, 0.740. Complementa p_fine sin repetir 0.715, 0.730 ni 0.745.'

if ($LASTEXITCODE -ne 0) {
  throw "Fallo el curado de $Experiment"
}

New-GnuplotPlots $Experiment "$Base/out/experiments/$Experiment/manifest.tsv"
New-TimeDiagnostics $Experiment

Write-Host 'Cola p_narrow completa.'
