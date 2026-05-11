param(
  [switch]$Controller,
  [string]$OutRoot = '',
  [int]$Fig3MaxParallel = 3,
  [int]$Fig3Reps = 200,
  [int]$Fig3NDIV = 401,
  [int]$PlaneJobs = 12,
  [int]$PlaneNDiv = 10,
  [int]$PlaneReps = 5,
  [double]$DegreeAlpha = 1.0,
  [double]$DegreeFactorMin = 0.3333333333333333,
  [double]$DegreeFactorMax = 3.0,
  [switch]$IncludeBonusAlpha5Symmetric
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Double {
  param([double]$Value)
  return [string]::Format($InvariantCulture, '{0:g}', $Value)
}

if ($OutRoot -eq '') {
  $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $OutRoot = "c_paper/out/experiments/degree_linear_overnight_fig3_thermo_$stamp"
}

if (-not [System.IO.Path]::IsPathRooted($OutRoot)) {
  $OutRoot = Join-Path $Repo $OutRoot
}
$OutRoot = [System.IO.Path]::GetFullPath($OutRoot)
$OutRoot = $OutRoot -replace '\\','/'
$LogDir = Join-Path $OutRoot 'logs'
$ControllerLog = Join-Path $OutRoot 'controller.log'
$LauncherLog = Join-Path $OutRoot 'launcher.log'

if (-not $Controller) {
  New-Item -ItemType Directory -Force -Path $OutRoot,$LogDir | Out-Null
  $scriptPath = Join-Path $PSScriptRoot 'run_degree_overnight_fig3_and_thermo.ps1'
  $argsList = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $scriptPath,
    '-Controller',
    '-OutRoot', $OutRoot,
    '-Fig3MaxParallel', "$Fig3MaxParallel",
    '-Fig3Reps', "$Fig3Reps",
    '-Fig3NDIV', "$Fig3NDIV",
    '-PlaneJobs', "$PlaneJobs",
    '-PlaneNDiv', "$PlaneNDiv",
    '-PlaneReps', "$PlaneReps",
    '-DegreeAlpha', (Format-Double $DegreeAlpha),
    '-DegreeFactorMin', (Format-Double $DegreeFactorMin),
    '-DegreeFactorMax', (Format-Double $DegreeFactorMax)
  )
  if ($IncludeBonusAlpha5Symmetric) {
    $argsList += '-IncludeBonusAlpha5Symmetric'
  }
  $p = Start-Process powershell.exe -ArgumentList $argsList -WorkingDirectory $Repo -WindowStyle Hidden -PassThru `
       -RedirectStandardOutput $LauncherLog -RedirectStandardError (Join-Path $LogDir 'controller.err.log')
  Write-Host "Controlador nocturno lanzado: PID $($p.Id)"
  Write-Host "OutRoot: $OutRoot"
  Write-Host "Log controlador: $ControllerLog"
  exit 0
}

New-Item -ItemType Directory -Force -Path $OutRoot,$LogDir | Out-Null
"time`tmessage" | Set-Content -Path $ControllerLog

function Write-Log([string]$Message) {
  ("{0}`t{1}" -f (Get-Date -Format s), $Message) | Tee-Object -FilePath $ControllerLog -Append
}

Write-Log "starting overnight degree-linear queue alpha=$(Format-Double $DegreeAlpha) clamp=[$(Format-Double $DegreeFactorMin),$(Format-Double $DegreeFactorMax)]"
Write-Log "phase 1: Fig. 3 sweep_b, N1=N2=1000, P11=P22=6/(N-1), p12 paper list, reps=$Fig3Reps, ndiv=$Fig3NDIV"

$fig3Root = Join-Path $OutRoot 'fig3_degree_alpha1'
& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_sweep_b_fig3_degree_queue.ps1 `
  -Controller `
  -OutRoot $fig3Root `
  -MaxParallel $Fig3MaxParallel `
  -Reps $Fig3Reps `
  -NDIV $Fig3NDIV `
  -T_MCS 1000 `
  -T_MAX 50000 `
  -W 2000 `
  -DegreeAlpha $DegreeAlpha `
  -DegreeFactorMin $DegreeFactorMin `
  -DegreeFactorMax $DegreeFactorMax *>&1 |
  Tee-Object -FilePath (Join-Path $LogDir 'fig3_degree_controller.stdout.log') -Append

if ($LASTEXITCODE -ne 0) {
  throw "Fallo la fase Fig. 3 con codigo $LASTEXITCODE"
}
Write-Log "phase 1 completed"

Write-Log "phase 2: three initial-plane checks matching Fermi thermodynamic-limit cases, with symmetric N increased"
$before = Get-Date
& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
  -Preset degreeThermoTargeted `
  -UpdateRule 2 `
  -DegreeAlpha $DegreeAlpha `
  -DegreeFactorMin $DegreeFactorMin `
  -DegreeFactorMax $DegreeFactorMax `
  -Jobs $PlaneJobs `
  -NDiv $PlaneNDiv `
  -NReps $PlaneReps *>&1 |
  Tee-Object -FilePath (Join-Path $LogDir 'initial_plane_degree.stdout.log') -Append

if ($LASTEXITCODE -ne 0) {
  throw "Fallo la fase initial_plane con codigo $LASTEXITCODE"
}

$manifest = Get-ChildItem -LiteralPath 'c_paper/out/logs' -Filter 'initial_plane_queue_degreeThermoTargeted_*.tsv' |
  Where-Object { $_.LastWriteTime -ge $before.AddMinutes(-1) } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if ($null -eq $manifest) {
  Write-Log "WARN no encuentro manifest nuevo para curar initial_plane"
} else {
  $experimentName = '2026-05-11_degree_linear_thermodynamic_limit'
  & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/curate_initial_plane_experiment.ps1 `
    -Manifest $manifest.FullName `
    -Experiment $experimentName `
    -Title 'Degree-linear thermodynamic-limit checks' `
    -Question 'Repeat the Fermi thermodynamic-limit and high-connectivity checks with UPDATE_RULE=2, alpha=1, clamp=[1/3,3]. Symmetric N is slightly increased.' `
    -Notes 'Jobs: N1=N2=800 p12=0.05 B=1.02; N1=800 N2=300 p12=0.02 B=1.06; N1=N2=500 p12=0.3 B=1.3. All use P11=P22=0.9, R=0, E=-0.4.' *>&1 |
    Tee-Object -FilePath (Join-Path $LogDir 'curate_initial_plane.stdout.log') -Append
  Write-Log "phase 2 completed and curated into c_paper/out/experiments/$experimentName"
}

if ($IncludeBonusAlpha5Symmetric) {
  Write-Log "bonus requested but not implemented as a separate preset in this launcher; skipping"
}

Write-Log "overnight degree-linear queue completed"
