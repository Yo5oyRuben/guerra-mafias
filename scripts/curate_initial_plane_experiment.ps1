param(
  [Parameter(Mandatory=$true)][string]$Manifest,
  [Parameter(Mandatory=$true)][string]$Experiment,
  [Parameter(Mandatory=$true)][string]$Title,
  [Parameter(Mandatory=$true)][string]$Question,
  [string]$Notes = ''
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$ExperimentRoot = "$Base/out/experiments/$Experiment"
$RawDir = "$ExperimentRoot/raw"
$PartsDir = "$ExperimentRoot/parts"
$PlotsDir = "$ExperimentRoot/plots"
$LogsDir = "$ExperimentRoot/logs"

function Get-TagFromOutput([string]$Path) {
  $name = [IO.Path]::GetFileNameWithoutExtension($Path)
  return $name -replace '^initial_plane__',''
}

New-Item -ItemType Directory -Force -Path $RawDir,$PartsDir,$PlotsDir,$LogsDir | Out-Null

$rows = Import-Csv -Delimiter "`t" -Path $Manifest
if ($rows.Count -eq 0) {
  throw "El manifest no tiene filas: $Manifest"
}

Copy-Item -LiteralPath $Manifest -Destination "$ExperimentRoot/manifest.tsv" -Force

$sourceLog = $Manifest -replace '\.tsv$','.log'
if (Test-Path -LiteralPath $sourceLog) {
  Copy-Item -LiteralPath $sourceLog -Destination $LogsDir -Force
}

foreach ($row in $rows) {
  $tag = Get-TagFromOutput $row.output
  $sourceRaw = $row.output
  $sourcePlot = $row.plot
  $sourceParts = "$Base/out/raw/initial_plane/parts/$tag"

  if (Test-Path -LiteralPath $sourceRaw) {
    Copy-Item -LiteralPath $sourceRaw -Destination $RawDir -Force
  } else {
    Write-Warning "No existe raw: $sourceRaw"
  }

  if (Test-Path -LiteralPath $sourcePlot) {
    Copy-Item -LiteralPath $sourcePlot -Destination $PlotsDir -Force
  } else {
    Write-Warning "No existe plot: $sourcePlot"
  }

  if (Test-Path -LiteralPath $sourceParts) {
    Copy-Item -LiteralPath $sourceParts -Destination $PartsDir -Recurse -Force
  } else {
    Write-Warning "No existe parts: $sourceParts"
  }
}

$notesText = @"
# $Title

Pregunta:
$Question

Fuente:
- Manifest original: $Manifest
- Copiado el: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Contenido:
- manifest.tsv: indice del lote.
- raw/: ficheros unidos de cada simulacion.
- parts/: parciales de la ejecucion paralela.
- plots/: figuras generadas con gnuplot.
- logs/: log de ejecucion de la cola.

Notas:
$Notes
"@

$notesText | Set-Content -Encoding UTF8 -LiteralPath "$ExperimentRoot/notes.md"

Write-Host "Experimento curado: $ExperimentRoot"
Write-Host "Simulaciones copiadas: $($rows.Count)"
