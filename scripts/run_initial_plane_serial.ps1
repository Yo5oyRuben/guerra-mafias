param(
  [string]$OutDir = 'build'
)

$Base = 'c_paper'

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

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
New-Item -ItemType Directory -Force -Path "$Base/out/raw/initial_plane" | Out-Null

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

$exe = Join-Path $OutDir 'run_initial_plane_scan.exe'

& $CC @flags @core @src '-lm' '-o' $exe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Compilado: $exe"
& $exe
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Ejecucion terminada.'
Write-Host "$Base/out/raw/initial_plane/initial_plane_test.txt"
