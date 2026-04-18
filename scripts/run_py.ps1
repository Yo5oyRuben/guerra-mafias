param(
  [Parameter(Mandatory=$true)]
  [string]$Script,
  [string[]]$Args
)

if (-not (Test-Path '.\.venv\Scripts\python.exe')) {
  Write-Error 'No existe .venv. Crea el entorno con: python -m venv .venv'
  exit 1
}

& .\.venv\Scripts\python.exe $Script @Args
