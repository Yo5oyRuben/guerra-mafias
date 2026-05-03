param(
  [int]$Jobs = 12,
  [int]$NDiv = -1,
  [int]$NReps = -1,
  [string]$OutDir = 'build',
  [string]$Output = ''
)

powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/run_initial_plane_parallel.ps1" `
  -Jobs $Jobs `
  -NDiv $NDiv `
  -NReps $NReps `
  -OutDir $OutDir `
  -Output $Output

exit $LASTEXITCODE
