param(
  [int]$Jobs = 12,
  [int]$NDiv = 8,
  [int]$NReps = 3,
  [string]$Experiment = '2026-05-06_relaxation_p073_TMAX200k'
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$ExperimentRoot = "$Base/out/experiments/$Experiment"
$RawDir = "$ExperimentRoot/raw"
$PartsDir = "$ExperimentRoot/parts"
$PlotsDir = "$ExperimentRoot/plots"
$LogsDir = "$ExperimentRoot/logs"
$LogDir = "$Base/out/logs"

New-Item -ItemType Directory -Force -Path $RawDir,$PartsDir,$PlotsDir,$LogsDir | Out-Null

$before = @{}
Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationP073T200k_*.tsv' -ErrorAction SilentlyContinue |
  ForEach-Object { $before[$_.FullName] = $true }

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
  -Preset relaxationP073T200k -Jobs $Jobs -NDiv $NDiv -NReps $NReps -NoPlot

if ($LASTEXITCODE -ne 0) {
  throw "La cola relaxationP073T200k fallo con codigo $LASTEXITCODE"
}

$manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationP073T200k_*.tsv' |
  Where-Object { -not $before.ContainsKey($_.FullName) } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $manifest) {
  $manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationP073T200k_*.tsv' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

if (-not $manifest) {
  throw 'No encuentro el manifest relaxationP073T200k despues de la ejecucion.'
}

$rows = Import-Csv -Delimiter "`t" -LiteralPath $manifest.FullName
Copy-Item -LiteralPath $manifest.FullName -Destination "$ExperimentRoot/manifest.tsv" -Force

$sourceLog = $manifest.FullName -replace '\.tsv$','.log'
if (Test-Path -LiteralPath $sourceLog) {
  Copy-Item -LiteralPath $sourceLog -Destination $LogsDir -Force
}

foreach ($row in $rows) {
  $name = [IO.Path]::GetFileNameWithoutExtension($row.output)
  $tag = $name -replace '^initial_plane__',''
  $sourceParts = "$Base/out/raw/initial_plane/parts/$tag"

  if (Test-Path -LiteralPath $row.output) {
    Copy-Item -LiteralPath $row.output -Destination $RawDir -Force
  }

  if (Test-Path -LiteralPath $sourceParts) {
    Copy-Item -LiteralPath $sourceParts -Destination $PartsDir -Recurse -Force
  }
}

$notes = @"
# Relaxation P073 TMAX=200000

Pregunta:
Comprobar si el caso delicado de alta conectividad P11=P22=0.73 estabiliza al duplicar T_MAX de 100000 a 200000.

Parametros:
- N1=N2=500
- P11=P22=0.73
- P12=0.20
- b=1.15
- R=0
- E=-0.4
- T_MCS=1000
- T_MAX=200000
- W=2000
- NDiv=$NDiv
- NReps=$NReps

Fuente:
- Manifest original: $($manifest.FullName)
- Copiado el: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$notes | Set-Content -Encoding UTF8 -LiteralPath "$ExperimentRoot/notes.md"

$row = $rows[0]
$rawPath = Join-Path $RawDir ([IO.Path]::GetFileName($row.output))
$plotPath = Join-Path $PlotsDir 'conn_p073_TMAX_200000.png'
& gnuplot -e "tmax=200000; infile='$($rawPath.Replace('\','/'))'; outfile='$($plotPath.Replace('\','/'))'" "$Base/out/gp/plot_initial_plane.gp"
if ($LASTEXITCODE -ne 0) {
  throw "Fallo gnuplot para $rawPath"
}

& .venv/Scripts/python.exe py/plot_initial_plane_time_diagnostics.py $ExperimentRoot

Write-Host "Experimento curado: $ExperimentRoot"
Write-Host "Simulaciones copiadas: $($rows.Count)"
