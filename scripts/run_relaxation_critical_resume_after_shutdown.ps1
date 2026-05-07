param(
  [int]$Jobs = 12,
  [int]$NDiv = 8,
  [string]$ExperimentPrefix = '2026-05-06_relaxation_critical_TMAX400k'
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
    $n1 = Safe-PlotToken $row.N1
    $n2 = Safe-PlotToken $row.N2
    $reps = Safe-PlotToken $row.reps
    $outfile = Join-Path $plots ("plot_{0:D2}_N1_{1}_N2_{2}_P_{3}_TMAX_{4}_reps_{5}.png" -f [int]$row.index,$n1,$n2,$p,$tmax,$reps)

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

function Invoke-Queue([string]$Preset, [int]$NReps) {
  New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
  $before = @{}
  Get-ChildItem -LiteralPath $LogDir -Filter "initial_plane_queue_${Preset}_*.tsv" -ErrorAction SilentlyContinue |
    ForEach-Object { $before[$_.FullName] = $true }

  & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
    -Preset $Preset -Jobs $Jobs -NDiv $NDiv -NReps $NReps -NoPlot

  if ($LASTEXITCODE -ne 0) {
    throw "La cola $Preset fallo con codigo $LASTEXITCODE"
  }

  return Get-NewManifest $Preset $before
}

function Invoke-CuratedBlock(
  [string]$Preset,
  [int]$NReps,
  [string]$Experiment,
  [string]$Title,
  [string]$Question,
  [string]$Notes
) {
  $manifest = Invoke-Queue $Preset $NReps

  & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/curate_initial_plane_experiment.ps1 `
    -Manifest $manifest.FullName `
    -Experiment $Experiment `
    -Title $Title `
    -Question $Question `
    -Notes $Notes

  if ($LASTEXITCODE -ne 0) {
    throw "Fallo el curado de $Experiment"
  }

  New-GnuplotPlots $Experiment "$Base/out/experiments/$Experiment/manifest.tsv"
  New-TimeDiagnostics $Experiment
}

function New-CombinedNScalingManifest([string]$OriginalManifest, [string]$ResumeManifest) {
  $stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
  $combined = "$LogDir/initial_plane_queue_relaxationCriticalNScalingT400k_combined_resume_$stamp.tsv"
  "index`tN1`tN2`tP11`tP12`tP22`tB`tR`tE`tndiv`treps`toutput`tplot" |
    Set-Content -Encoding ASCII -LiteralPath $combined

  $rows = @()
  $rows += @(Import-Csv -Delimiter "`t" -LiteralPath $OriginalManifest | Where-Object { $_.N1 -eq '250' -and $_.N2 -eq '250' })
  $rows += @(Import-Csv -Delimiter "`t" -LiteralPath $ResumeManifest)

  for ($i = 0; $i -lt $rows.Count; $i++) {
    $r = $rows[$i]
    "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}`t{12}" -f `
      ($i + 1), $r.N1, $r.N2, $r.P11, $r.P12, $r.P22, $r.B, $r.R, $r.E, $r.ndiv, $r.reps, $r.output, $r.plot |
      Add-Content -Encoding ASCII -LiteralPath $combined
  }

  return $combined
}

$originalNScaling = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationCriticalNScalingT400k_*.tsv' |
  Where-Object { $_.Name -notmatch 'combined|Remaining' } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $originalNScaling) {
  throw 'No encuentro el manifest original del bloque N scaling con N=250 completo.'
}

$resumeNScaling = Invoke-Queue 'relaxationCriticalNScalingRemainingT400k' 3
$combinedNScaling = New-CombinedNScalingManifest $originalNScaling.FullName $resumeNScaling.FullName

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/curate_initial_plane_experiment.ps1 `
  -Manifest $combinedNScaling `
  -Experiment "${ExperimentPrefix}_n_scaling" `
  -Title 'Relaxation critical N scaling TMAX=400000' `
  -Question 'Comprobar si el caso lento P11=P22=0.73 cambia con el tamano del sistema o apunta a limite termodinamico estable.' `
  -Notes 'Reanudado tras apagado accidental: N=250 ya habia terminado en la cola original; N=750 y N=1000 se recalculan en la cola Remaining. P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4.'

if ($LASTEXITCODE -ne 0) {
  throw 'Fallo el curado combinado de N scaling.'
}

New-GnuplotPlots "${ExperimentPrefix}_n_scaling" "$Base/out/experiments/${ExperimentPrefix}_n_scaling/manifest.tsv"
New-TimeDiagnostics "${ExperimentPrefix}_n_scaling"

Invoke-CuratedBlock `
  -Preset 'relaxationCriticalAsymT400k' `
  -NReps 3 `
  -Experiment "${ExperimentPrefix}_asym" `
  -Title 'Relaxation critical asymmetric sizes TMAX=400000' `
  -Question 'Ver si la asimetria fuerte de tamano preserva, desplaza o destruye la zona lenta observada en el caso simetrico critico.' `
  -Notes 'N1:N2 = 400:1200 y 1200:400. P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4.'

Invoke-CuratedBlock `
  -Preset 'relaxationCriticalStatsT400k' `
  -NReps 10 `
  -Experiment "${ExperimentPrefix}_stats_reps10" `
  -Title 'Relaxation critical high statistics TMAX=400000' `
  -Question 'Separar fluctuacion entre redes/condiciones iniciales de estructura real del diagrama en el punto mas delicado.' `
  -Notes 'N1=N2=500, P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4, reps=10.'

Write-Host 'Reanudacion critica completa.'
