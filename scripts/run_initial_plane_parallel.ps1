param(
  [int]$Jobs = 12,
  [int]$NDiv = -1,
  [int]$NReps = -1,
  [string]$OutDir = 'build',
  [string]$Output = ''
)

$Base = 'c_paper'
$PartialRoot = "$Base/out/raw/initial_plane/parts"

if ($Jobs -lt 1) {
  Write-Error 'Jobs debe ser >= 1.'
  exit 1
}

$gcc = Get-Command gcc -ErrorAction SilentlyContinue
$clang = Get-Command clang -ErrorAction SilentlyContinue

if ($gcc) {
  $CC = $gcc.Source
} elseif ($clang) {
  $CC = $clang.Source
} else {
  Write-Error 'No se encontro gcc ni clang en PATH. Instala MSYS2/MinGW o LLVM/Clang y vuelve a intentar.'
  exit 1
}

$configText = Get-Content "$Base/config.h" -Raw

function Get-DefineValue([string]$Name) {
  if ($configText -match "(?m)^\s*#define\s+$Name\s+(.+?)\s*$") {
    return ($Matches[1] -replace '/\*.*?\*/','').Trim()
  }
  return 'NA'
}

function Safe-Tag([string]$Value) {
  $s = $Value.Trim()
  $s = $s -replace '\s+', ''
  $s = $s -replace '\(', ''
  $s = $s -replace '\)', ''
  $s = $s -replace '\.', 'p'
  $s = $s -replace '-', 'm'
  $s = $s -replace '\+', 'p'
  $s = $s -replace '/', 'over'
  $s = $s -replace '[^A-Za-z0-9_]', '_'
  if ($s.Length -eq 0) { return 'NA' }
  return $s
}

if ($NDiv -lt 0) {
  if ($configText -match '#define\s+N_INI_NDIV\s+(\d+)') {
    $NDiv = [int]$Matches[1]
  } else {
    $NDiv = 6
  }
}
if ($NReps -lt 0) {
  if ($configText -match '#define\s+N_INI_COND\s+(\d+)') {
    $NReps = [int]$Matches[1]
  } else {
    $NReps = 1
  }
}

$tagParts = @(
  "N1_$(Safe-Tag (Get-DefineValue 'N1'))",
  "N2_$(Safe-Tag (Get-DefineValue 'N2'))",
  "P11_$(Safe-Tag (Get-DefineValue 'P11'))",
  "P12_$(Safe-Tag (Get-DefineValue 'P12'))",
  "P22_$(Safe-Tag (Get-DefineValue 'P22'))",
  "B_$(Safe-Tag (Get-DefineValue 'B'))",
  "R_$(Safe-Tag (Get-DefineValue 'R'))",
  "E_$(Safe-Tag (Get-DefineValue 'E'))",
  "TMAX_$(Safe-Tag (Get-DefineValue 'T_MAX'))",
  "ndiv_$NDiv",
  "reps_$NReps"
)
$runTag = $tagParts -join '__'
$PartialDir = Join-Path $PartialRoot $runTag

if ($Output -eq '') {
  $Output = "$Base/out/raw/initial_plane/initial_plane__$runTag.txt"
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path $PartialDir | Out-Null
New-Item -ItemType Directory -Force -Path (Split-Path $Output -Parent) | Out-Null

Write-Host "Configuracion initial plane: Jobs=$Jobs NDiv=$NDiv NReps=$NReps"
Write-Host "Etiqueta: $runTag"
Write-Host "Carpeta de parciales: $PartialDir"

$flags = @(
  '-O3','-std=c90','-pedantic','-Wall','-Wextra',
  '-I',$Base,
  '-I',"$Base/core",
  '-I',"$Base/apps/well_mixed_limit"
)

$core = @(
  "$Base/core/rng.c",
  "$Base/core/graph.c",
  "$Base/core/state.c",
  "$Base/core/payoff.c",
  "$Base/core/dynamics.c",
  "$Base/core/sim.c",
  "$Base/core/utils.c",
  "$Base/core/io.c"
)

$src = @(
  "$Base/apps/well_mixed_limit/run_initial_plane_scan.c",
  "$Base/apps/well_mixed_limit/scan_initial_plane.c"
)

$exe = Join-Path $OutDir 'run_initial_plane_scan_parallel.exe'

& $CC @flags @core @src '-lm' '-o' $exe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$totalIx = $NDiv + 1
if ($Jobs -gt $totalIx) { $Jobs = $totalIx }
$chunk = [int][Math]::Ceiling($totalIx / [double]$Jobs)

Remove-Item -Path (Join-Path $PartialDir 'part_*.txt') -ErrorAction SilentlyContinue

$processes = @()
$parts = @()

for ($job = 0; $job -lt $Jobs; $job++) {
  $ixMin = $job * $chunk
  $ixMax = [Math]::Min($NDiv, (($job + 1) * $chunk) - 1)
  if ($ixMin -gt $ixMax) { continue }

  $part = Join-Path $PartialDir ("part_{0:D3}_ix_{1:D3}_{2:D3}.txt" -f $job,$ixMin,$ixMax)
  $parts += $part

  Write-Host "Lanzando job ${job}: ix=$ixMin..$ixMax -> $part"
  $processes += Start-Process `
    -FilePath $exe `
    -ArgumentList @($ixMin, $ixMax, $part, $NDiv, $NReps) `
    -WorkingDirectory (Get-Location) `
    -PassThru `
    -WindowStyle Hidden
}

foreach ($p in $processes) {
  $p.WaitForExit()
  if ($p.ExitCode -ne 0) {
    Write-Error "Un proceso fallo con codigo $($p.ExitCode)."
    exit $p.ExitCode
  }
}

if ($parts.Count -eq 0) {
  Write-Error 'No se genero ningun fichero parcial.'
  exit 1
}

$first = $true
Remove-Item -LiteralPath $Output -ErrorAction SilentlyContinue
New-Item -ItemType File -Path $Output -Force | Out-Null

foreach ($part in $parts) {
  if (!(Test-Path $part)) {
    Write-Error "No existe el parcial esperado: $part"
    exit 1
  }

  if ($first) {
    Get-Content $part | Add-Content $Output
    $first = $false
  } else {
    Get-Content $part | Where-Object { $_ -and $_[0] -ne '#' } | Add-Content $Output
  }
}

Write-Host "Ejecucion paralela terminada."
Write-Host "Salida final: $Output"
Write-Host "Parciales: $PartialDir"
