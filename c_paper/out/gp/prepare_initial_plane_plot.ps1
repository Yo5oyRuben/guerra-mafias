param(
  [string]$Indir = '',
  [string]$Infile = '',
  [Parameter(Mandatory=$true)][string]$Points,
  [Parameter(Mandatory=$true)][string]$Fixed,
  [Parameter(Mandatory=$true)][string]$PlotDir
)

New-Item -ItemType Directory -Force -Path $PlotDir | Out-Null

if ($Infile -ne '') {
  if (!(Test-Path -LiteralPath $Infile)) {
    Write-Error "Input file not found: $Infile"
    exit 1
  }

  Get-Content -LiteralPath $Infile |
    Where-Object { $_ -and $_[0] -ne '#' } |
    Set-Content -Encoding ASCII -LiteralPath $Points

  $header = Get-Content -LiteralPath $Infile |
    Where-Object { $_ -like '# A:*' } |
    Select-Object -First 1
} else {
  if ($Indir -eq '') {
    Write-Error "Define either Infile or Indir."
    exit 1
  }

  $parts = Get-ChildItem -LiteralPath $Indir -Filter 'part_*.txt' | Sort-Object Name
  if ($parts.Count -eq 0) {
    Write-Error "No part_*.txt files found in $Indir"
    exit 1
  }

  $parts | ForEach-Object {
    Get-Content -LiteralPath $_.FullName | Where-Object { $_ -and $_[0] -ne '#' }
  } | Set-Content -Encoding ASCII -LiteralPath $Points

  $header = Get-Content -LiteralPath $parts[0].FullName |
    Where-Object { $_ -like '# A:*' } |
    Select-Object -First 1
}

if (-not $header) {
  Write-Error "Could not find analytic fixed-point header."
  exit 1
}

[regex]::Matches($header, "(A'|B'|[ABCDE]):?=?\(([-0-9.]+),([-0-9.]+)\)") |
  ForEach-Object {
    "{0} {1} {2}" -f $_.Groups[1].Value,$_.Groups[2].Value,$_.Groups[3].Value
  } |
  Set-Content -Encoding ASCII -LiteralPath $Fixed
