param(
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

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$flags = @('-O2','-std=c90','-pedantic','-Wall','-Wextra','-I','c')

& $CC @flags 'c/model.c' 'c/run_well_mixed.c' '-o' (Join-Path $OutDir 'run_well_mixed.exe')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $CC @flags 'c/model.c' 'c/run_network.c' '-o' (Join-Path $OutDir 'run_network.exe')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Compilacion correcta con $CC"
Write-Host "Ejecutables: $OutDir\\run_well_mixed.exe y $OutDir\\run_network.exe"
