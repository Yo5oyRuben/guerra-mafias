param(
  [int]$Jobs = 12,
  [int]$NDiv = 8,
  [int]$NReps = 3,
  [string]$Experiment = '2026-05-03_highN_strong_asymmetry'
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
Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_highNAsymLarge_*.tsv' -ErrorAction SilentlyContinue |
  ForEach-Object { $before[$_.FullName] = $true }

& powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_queue.ps1 `
  -Preset highNAsymLarge -Jobs $Jobs -NDiv $NDiv -NReps $NReps

if ($LASTEXITCODE -ne 0) {
  throw "La cola highNAsymLarge fallo con codigo $LASTEXITCODE"
}

$manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_highNAsymLarge_*.tsv' |
  Where-Object { -not $before.ContainsKey($_.FullName) } |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 1

if (-not $manifest) {
  $manifest = Get-ChildItem -LiteralPath $LogDir -Filter 'initial_plane_queue_highNAsymLarge_*.tsv' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
}

if (-not $manifest) {
  throw 'No encuentro el manifest highNAsymLarge despues de la ejecucion.'
}

$rows = Import-Csv -Delimiter "`t" -LiteralPath $manifest.FullName
$targetManifest = "$ExperimentRoot/manifest.tsv"

if (-not (Test-Path -LiteralPath $targetManifest)) {
  Copy-Item -LiteralPath $manifest.FullName -Destination $targetManifest -Force
} else {
  $rows | ConvertTo-Csv -Delimiter "`t" -NoTypeInformation |
    Select-Object -Skip 1 |
    ForEach-Object { $_ -replace '"','' } |
    Add-Content -Encoding ASCII -LiteralPath $targetManifest
}

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

$note = @"

## highNAsymLarge añadido $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Se añaden mapas initial_plane con N mayores y asimetría fuerte:
- N1/N2 = 400/1200 y 1200/400: escala 1:3 del caso original 200/600.
- N1/N2 = 300/1500 y 1500/300: asimetría 1:5 para forzar diferencia de tamaños.
- En ambos casos se repiten los dos regímenes previos: (P12,B)=(0.02,1.06) y (0.03,1.10).
- NDiv=$NDiv, NReps=$NReps, Jobs=$Jobs.
- Manifest de la tanda: $($manifest.FullName)
"@

Add-Content -Encoding UTF8 -LiteralPath "$ExperimentRoot/notes.md" -Value $note

Write-Host "Copiados $($rows.Count) experimentos nuevos a $ExperimentRoot"
