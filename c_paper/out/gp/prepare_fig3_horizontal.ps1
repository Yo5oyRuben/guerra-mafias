param(
  [string]$ExpDir = 'c_paper/out/experiments/01_paper_baselines',
  [Parameter(Mandatory=$true)][string]$Combined
)

$ErrorActionPreference = 'Stop'
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Parse-P12FromName {
  param([string]$Name)
  if ($Name -match 'p12_([^\.]+)') {
    return [double]::Parse(($Matches[1] -replace 'p','.'), $InvariantCulture)
  }
  return $null
}

function Read-Sweep {
  param([string]$Path)

  $rows = @()
  Get-Content -LiteralPath $Path |
    Where-Object { $_ -and $_[0] -ne '#' } |
    ForEach-Object {
      $cols = $_ -split "\s+"
      if ($cols.Count -lt 7) { return }
      $rows += [pscustomobject]@{
        b = [double]::Parse($cols[0], $InvariantCulture)
        c = [double]::Parse($cols[5], $InvariantCulture)
        sem = [double]::Parse($cols[6], $InvariantCulture)
      }
    }
  return $rows
}

$rawDir = Join-Path $ExpDir 'raw'
$files = @(Get-ChildItem -LiteralPath $rawDir -Filter 'fig3_paper_p12_*.tsv' |
  Where-Object { $_.Length -gt 0 } |
  Sort-Object @{ Expression = { Parse-P12FromName $_.Name } })

if ($files.Count -eq 0) {
  throw "No fig3_paper_p12_*.tsv files found in $rawDir"
}

$baseFile = $files | Where-Object { (Parse-P12FromName $_.Name) -eq 0.0 } | Select-Object -First 1
if (-not $baseFile) {
  throw "No p12=0 baseline found."
}

$base = @{}
foreach ($row in Read-Sweep $baseFile.FullName) {
  $base[[string]::Format($InvariantCulture, "{0:F12}", $row.b)] = $row.c
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# b p12 c c_sem delta_c")

foreach ($file in $files) {
  $p12 = Parse-P12FromName $file.Name
  foreach ($row in Read-Sweep $file.FullName) {
    $key = [string]::Format($InvariantCulture, "{0:F12}", $row.b)
    $delta = $row.c - $base[$key]
    $lines.Add([string]::Format($InvariantCulture, "{0:F12} {1:F12} {2:F12} {3:F12} {4:F12}", $row.b, $p12, $row.c, $row.sem, $delta))
  }
  $lines.Add("")
  $lines.Add("")
}

$dir = Split-Path -Parent $Combined
if ($dir -and -not (Test-Path -LiteralPath $dir)) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}
$lines | Set-Content -LiteralPath $Combined -Encoding ASCII
