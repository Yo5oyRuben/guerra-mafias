param(
  [ValidateSet('all', 'p12', 'b', 'grid', 'refine', 'frontier', 'robust', 'followup')]
  [string]$Scan = 'all',
  [int]$Jobs = 9,
  [int]$NDiv = 8,
  [int]$NReps = 3,
  [switch]$SkipExisting
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

  $queueArgs = @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', 'scripts/run_initial_plane_queue.ps1',
    '-Preset', $Spec.Preset,
    '-Jobs', $Jobs,
    '-NDiv', $NDiv,
    '-NReps', $NReps,
    '-NoPlot'
  )
  if ($SkipExisting) {
    $queueArgs += '-SkipExisting'
  }

  & powershell @queueArgs

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
  },
  [pscustomobject]@{
    Key = 'refine'
    Preset = 'torreCriticalP11P12RefineT400k'
    Experiment = 'torre_2026-05-08_p11_p12_refine_TMAX400k'
    Title = 'Torre refined P11-P12 boundary at B=1.15, TMAX400k'
    Question = 'Where is the transition boundary between P12=0.20 and P12=0.24 as P11=P22 changes?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 3
P12 values = 0.21, 0.22, 0.23
P11 = P22 values = 0.70, 0.73, 0.76, 0.80
Purpose: refine the P11-P12 transition boundary suggested by the coarse grid.
'@
  },
  [pscustomobject]@{
    Key = 'frontier'
    Preset = 'torreCriticalHighP11FrontierT400k'
    Experiment = 'torre_2026-05-08_high_p11_frontier_TMAX400k'
    Title = 'Torre high-P11 frontier at B=1.15, TMAX400k'
    Question = 'Does the critical boundary persist at higher P11 as P12 approaches 0.23?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 3
P12 = 0.21 with P11 = P22 = 0.77, 0.78, 0.79, 0.80
P12 = 0.22 with P11 = P22 = 0.79, 0.80, 0.82, 0.84
P12 = 0.23 with P11 = P22 = 0.80, 0.83, 0.86, 0.90
Purpose: follow the transition boundary toward high P11.
'@
  },
  [pscustomobject]@{
    Key = 'robust'
    Preset = 'torreCriticalBoundaryRobustT400k'
    Experiment = 'torre_2026-05-08_boundary_robust_TMAX400k'
    Title = 'Torre boundary robustness checks at B=1.15, TMAX400k'
    Question = 'Are selected near-boundary signals stable with higher replication?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 5
Points:
- P12 = 0.21, P11 = P22 = 0.80
- P12 = 0.22, P11 = P22 = 0.80
- P12 = 0.22, P11 = P22 = 0.82
- P12 = 0.23, P11 = P22 = 0.86
Purpose: higher-statistics checks near the inferred boundary.
'@
  },
  [pscustomobject]@{
    Key = 'followup'
    Preset = 'torreCriticalFrontierFollowupT400k'
    Experiment = 'torre_2026-05-09_frontier_followup_TMAX400k'
    Title = 'Torre frontier follow-up at B=1.15, TMAX400k'
    Question = 'Can the P11=P22 critical boundary be localized more tightly for P12=0.22, 0.23, and 0.24?'
    Notes = @'
T_MAX = 400000
N1 = N2 = 500
B = 1.15
R = 0
E = -0.4
NDiv = 8
NReps = 3
Points:
- P12 = 0.22, P11 = P22 = 0.81
- P12 = 0.23, P11 = P22 = 0.84, 0.85
- P12 = 0.24, P11 = P22 = 0.86, 0.88, 0.90
Purpose: follow the inferred P11-P12 critical boundary with a compact overnight package.
'@
  }
)

if ($Scan -ne 'all') {
  $specs = @($specs | Where-Object { $_.Key -eq $Scan })
}

foreach ($spec in $specs) {
  Invoke-Scan $spec
}
