param(
  [int]$Jobs = 12,
  [int]$NDiv = 8,
  [int]$NReps = 3,
  [string]$Experiment = '2026-05-05_relaxation_pilot_TMAX50k'
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
Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationPilot50k_*.tsv' -ErrorAction SilentlyContinue |
  ForEach-Object { $before[$_.FullName] = $true }

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
  -Preset relaxationPilot50k -Jobs $Jobs -NDiv $NDiv -NReps $NReps

if ($LASTEXITCODE -ne 0) {
  throw "La cola relaxationPilot50k fallo con codigo $LASTEXITCODE"
}

$manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationPilot50k_*.tsv' |
  Where-Object { -not $before.ContainsKey($_.FullName) } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $manifest) {
  $manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_relaxationPilot50k_*.tsv' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

if (-not $manifest) {
  throw 'No encuentro el manifest relaxationPilot50k despues de la ejecucion.'
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

  if (Test-Path -LiteralPath $row.plot) {
    Copy-Item -LiteralPath $row.plot -Destination $PlotsDir -Force
  }

  if (Test-Path -LiteralPath $sourceParts) {
    Copy-Item -LiteralPath $sourceParts -Destination $PartsDir -Recurse -Force
  }
}

$notes = @"
# Relaxation pilot TMAX=50000

Pregunta:
Comprobar si las zonas rojas de las figuras con T_MAX=25000 eran falta de tiempo de relajacion o relajacion lenta persistente.

Parametros:
- NDiv=$NDiv
- NReps=$NReps
- T_MCS=1000
- T_MAX=50000
- W=2000
- R=0
- E=-0.4

Casos:
- N1=N2=500, P11=P22=0.73, P12=0.20, b=1.15
- N1=N2=500, P11=P22=0.90, P12=0.20, b=1.15
- N1=400, N2=1200, P11=P22=0.9, P12=0.02, b=1.06
- N1=1200, N2=400, P11=P22=0.9, P12=0.02, b=1.06

Fuente:
- Manifest original: $($manifest.FullName)
- Copiado el: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$notes | Set-Content -Encoding UTF8 -LiteralPath "$ExperimentRoot/notes.md"

& gnuplot --version | Out-Null
foreach ($row in $rows) {
  $rawPath = Join-Path $RawDir ([IO.Path]::GetFileName($row.output))
  $plotPath = Join-Path $PlotsDir ([IO.Path]::GetFileName($row.plot))
  & gnuplot -e "tmax=50000; infile='$($rawPath.Replace('\','/'))'; outfile='$($plotPath.Replace('\','/'))'" "$Base/out/gp/plot_initial_plane.gp"
}

& .venv/Scripts/python.exe py/plot_initial_plane_time_diagnostics.py $ExperimentRoot

Write-Host "Experimento curado: $ExperimentRoot"
Write-Host "Simulaciones copiadas: $($rows.Count)"
