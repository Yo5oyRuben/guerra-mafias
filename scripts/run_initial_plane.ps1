param(
  [int]$Jobs = 12,
  [int]$NDiv = -1,
  [int]$NReps = -1,
  [string]$OutDir = 'build',
  [string]$Output = 'c_paper/out/raw/initial_plane/initial_plane_parallel.txt'
)

powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/run_initial_plane_parallel.ps1" `
  -Jobs $Jobs `
  -NDiv $NDiv `
  -NReps $NReps `
  -OutDir $OutDir `
  -Output $Output

exit $LASTEXITCODE
