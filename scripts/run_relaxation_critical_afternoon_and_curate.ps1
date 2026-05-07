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

function Invoke-CriticalBlock(
  [string]$Preset,
  [int]$NReps,
  [string]$Experiment,
  [string]$Title,
  [string]$Question,
  [string]$Notes
) {
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
    -Title $Title `
    -Question $Question `
    -Notes $Notes

  if ($LASTEXITCODE -ne 0) {
    throw "Fallo el curado de $Experiment"
  }

  New-GnuplotPlots $Experiment "$Base/out/experiments/$Experiment/manifest.tsv"
  New-TimeDiagnostics $Experiment
}

Invoke-CriticalBlock `
  -Preset 'relaxationCriticalPFineT400k' `
  -NReps 3 `
  -Experiment "${ExperimentPrefix}_p_fine" `
  -Title 'Relaxation critical fine connectivity scan TMAX=400000' `
  -Question 'Localizar si la relajacion lenta es una ventana estrecha alrededor de P11=P22=0.73 o un regimen amplio de conectividades medias-altas.' `
  -Notes 'N1=N2=500, P12=0.20, b=1.15, R=0, E=-0.4. Barrido P11=P22=0.70, 0.715, 0.745, 0.76, 0.80. El caso 0.73 ya existe como referencia.'

Invoke-CriticalBlock `
  -Preset 'relaxationCriticalNScalingT400k' `
  -NReps 3 `
  -Experiment "${ExperimentPrefix}_n_scaling" `
  -Title 'Relaxation critical N scaling TMAX=400000' `
  -Question 'Comprobar si el caso lento P11=P22=0.73 cambia con el tamano del sistema o apunta a limite termodinamico estable.' `
  -Notes 'N1=N2=250, 750, 1000. P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4.'

Invoke-CriticalBlock `
  -Preset 'relaxationCriticalAsymT400k' `
  -NReps 3 `
  -Experiment "${ExperimentPrefix}_asym" `
  -Title 'Relaxation critical asymmetric sizes TMAX=400000' `
  -Question 'Ver si la asimetria fuerte de tamano preserva, desplaza o destruye la zona lenta observada en el caso simetrico critico.' `
  -Notes 'N1:N2 = 400:1200 y 1200:400. P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4.'

Invoke-CriticalBlock `
  -Preset 'relaxationCriticalStatsT400k' `
  -NReps 10 `
  -Experiment "${ExperimentPrefix}_stats_reps10" `
  -Title 'Relaxation critical high statistics TMAX=400000' `
  -Question 'Separar fluctuacion entre redes/condiciones iniciales de estructura real del diagrama en el punto mas delicado.' `
  -Notes 'N1=N2=500, P11=P22=0.73, P12=0.20, b=1.15, R=0, E=-0.4, reps=10.'

Write-Host 'Cola critica completa.'
