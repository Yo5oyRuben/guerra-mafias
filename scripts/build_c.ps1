param(
  [ValidateSet('paper','mafia','legacy')]
  [string]$Model = 'paper',
  [string]$OutDir = 'build'
)

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

switch ($Model) {
  'paper'  { $Base = 'c_paper' }
  'mafia'  { $Base = 'c_mafia' }
  default  { $Base = 'c' }
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$flags = @(
  '-O3','-std=c90','-pedantic','-Wall','-Wextra',
  '-I',$Base,
  '-I',"$Base/core",
  '-I',"$Base/apps",
  '-I',"$Base/apps/sweep_b",
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

if ($Model -eq 'paper') {
  $src_wm = @(
    "$Base/apps/sweep_b/run_well_mixed.c",
    "$Base/apps/sweep_b/run_sweep_b.c"
  )

  $src_net = @(
    "$Base/apps/sweep_b/run_network.c",
    "$Base/apps/sweep_b/run_sweep_b.c"
  )

  $src_initial_plane = @(
    "$Base/apps/well_mixed_limit/run_initial_plane_scan.c",
    "$Base/apps/well_mixed_limit/scan_initial_plane.c"
  )
} else {
  $src_wm = @(
    "$Base/apps/run_well_mixed.c",
    "$Base/apps/run_sweep_b.c"
  )

  $src_net = @(
    "$Base/apps/run_network.c",
    "$Base/apps/run_sweep_b.c"
  )

  $src_initial_plane = @()
}

& $CC @flags @core @src_wm '-lm' '-o' (Join-Path $OutDir 'run_well_mixed.exe')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $CC @flags @core @src_net '-lm' '-o' (Join-Path $OutDir 'run_network.exe')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

if ($src_initial_plane.Count -gt 0) {
  & $CC @flags @core @src_initial_plane '-lm' '-o' (Join-Path $OutDir 'run_initial_plane_scan.exe')
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host "Compilacion correcta con $CC"
Write-Host "Modelo: $Model ($Base)"
Write-Host "Ejecutables en $OutDir"
