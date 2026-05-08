param(
  [ValidateSet('all', 'p12', 'b', 'grid')]
  [string]$Scan = 'all',
  [int]$Jobs = 9,
  [int]$NDiv = 8,
  [int]$NReps = 3
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$LogDir = "$Base/out/logs"
$Python = '.\.venv\Scripts\python.exe'

function Convert-ToGnuplotPath([string]$Path) {
  return $Path.Replace('\', '/')
}

function Get-NewManifest([string]$Preset, [hashtable]$Before) {
  $manifest = Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" -ErrorAction SilentlyContinue |
    Where-Object { -not $Before.ContainsKey($_.FullName) } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if (-not $manifest) {
    $manifest = Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1
  }

  if (-not $manifest) {
    throw "No encuentro manifest para $Preset."
  }

  return $manifest
}

function Invoke-Scan($Spec) {
  $before = @{}
  Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_$($Spec.Preset)_*.tsv" -ErrorAction SilentlyContinue |
    ForEach-Object { $before[$_.FullName] = $true }

  & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
    -Preset $Spec.Preset -Jobs $Jobs -NDiv $NDiv -NReps $NReps -NoPlot

  if ($LASTEXITCODE -ne 0) {
    throw "La cola $($Spec.Preset) fallo con codigo $LASTEXITCODE"
  }

  $manifest = Get-NewManifest $Spec.Preset $before

  & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/curate_initial_plane_experiment.ps1 `
    -Manifest $manifest.FullName `
    -Experiment $Spec.Experiment `
    -Title $Spec.Title `
    -Question $Spec.Question `
    -Notes $Spec.Notes

  if ($LASTEXITCODE -ne 0) {
    throw "La curacion de $($Spec.Preset) fallo con codigo $LASTEXITCODE"
  }

  $experimentRoot = "$Base/out/experiments/$($Spec.Experiment)"
  $rawDir = "$experimentRoot/raw"
  $plotDir = "$experimentRoot/plots"
  New-Item -ItemType Directory -Force -Path $plotDir | Out-Null

  foreach ($raw in Get-ChildItem -LiteralPath $rawDir -Filter 'initial_plane__*.txt' | Sort-Object Name) {
    $outfile = Join-Path $plotDir ($raw.BaseName + '.png')
    $infileGp = Convert-ToGnuplotPath $raw.FullName
    $outfileGp = Convert-ToGnuplotPath (Resolve-Path -LiteralPath (Split-Path -Parent $outfile)).Path
    $outfileGp = "$outfileGp/$([IO.Path]::GetFileName($outfile))"
    & gnuplot -e "infile='$infileGp'; outfile='$outfileGp'" c_paper/out/gp/plot_initial_plane.gp

    if ($LASTEXITCODE -ne 0) {
      throw "gnuplot fallo para $($raw.Name) con codigo $LASTEXITCODE"
    }
  }

  if (Test-Path -LiteralPath $Python) {
    & $Python py/plot_initial_plane_time_diagnostics.py $experimentRoot
  } else {
    & python py/plot_initial_plane_time_diagnostics.py $experimentRoot
  }

  if ($LASTEXITCODE -ne 0) {
    throw "diagnostics_time fallo para $($Spec.Experiment) con codigo $LASTEXITCODE"
  }

  Write-Host "Scan terminado: $($Spec.Experiment)"
  Write-Host "Manifest: $($manifest.FullName)"
}

$specs = @(
  [pscustomobject]@{
    Key = 'p12'
    Preset = 'torreCriticalP12ScanT400k'
    Experiment = 'torre_2026-05-07_p12_scan_TMAX400k'
    Title = 'Torre P12 scan at P11=P22=0.73, TMAX400k'
    Question = 'Does the critical/crossover region depend on absolute intra connectivity or on the intra/inter balance?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
P11 = P22 = 0.73
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 3
P12 values = 0.05, 0.10, 0.15, 0.25, 0.30, 0.40
Excluded because already covered elsewhere: P12 = 0.20
'@
  },
  [pscustomobject]@{
    Key = 'b'
    Preset = 'torreCriticalBScanT400k'
    Experiment = 'torre_2026-05-07_b_scan_TMAX400k'
    Title = 'Torre B scan at P11=P22=0.73, TMAX400k'
    Question = 'Does the observed critical point near P=0.73 shift with the defector payoff advantage B?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
P11 = P22 = 0.73
P12 = 0.20
R = 0
E = -0.4
NDiv = 8
NReps = 3
B values = 1.05, 1.10, 1.20, 1.30
Excluded because already covered elsewhere: B = 1.15
'@
  },
  [pscustomobject]@{
    Key = 'grid'
    Preset = 'torreCriticalP11P12GridT400k'
    Experiment = 'torre_2026-05-07_p11_p12_grid_TMAX400k'
    Title = 'Torre coarse P11-P12 grid at B=1.15, TMAX400k'
    Question = 'Does the slow/critical region form a boundary in the P11=P22 versus P12 plane?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 3
P12 values = 0.16, 0.20, 0.24
P11 = P22 values = 0.65, 0.70, 0.73, 0.76, 0.80
Purpose: cheap overnight grid to identify whether the transition boundary shifts in the P11-P12 plane.
'@
  }
)

if ($Scan -ne 'all') {
  $specs = @($specs | Where-Object { $_.Key -eq $Scan })
}

foreach ($spec in $specs) {
  Invoke-Scan $spec
}
