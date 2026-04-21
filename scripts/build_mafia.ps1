param(
  [string]$OutDir = 'build'
)

powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/build_c.ps1" -Model mafia -OutDir $OutDir
exit $LASTEXITCODE
