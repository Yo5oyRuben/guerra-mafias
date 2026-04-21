param(
  [string]$OutDir = 'build'
)

powershell -ExecutionPolicy Bypass -File "$PSScriptRoot/build_c.ps1" -Model paper -OutDir $OutDir
exit $LASTEXITCODE
