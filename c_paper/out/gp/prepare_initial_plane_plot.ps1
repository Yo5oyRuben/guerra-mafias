param(
  [string]$Indir = '',
  [string]$Infile = '',
  [Parameter(Mandatory=$true)][string]$Points,
  [Parameter(Mandatory=$true)][string]$Fixed,
  [string]$Params = '',
  [Parameter(Mandatory=$true)][string]$PlotDir
)

New-Item -ItemType Directory -Force -Path $PlotDir | Out-Null

function Get-HeaderValue([string[]]$Lines, [string]$Name) {
  $line = $Lines | Where-Object { $_ -match "^\s*#\s+$Name\s+" } | Select-Object -First 1
  if (-not $line) { return '' }
  return (($line -replace "^\s*#\s+$Name\s+", '')).Trim()
}

function Get-TagValue([string]$Tag, [string]$Name) {
  $match = [regex]::Match($Tag, "(^|__)$Name`_([^_]+)")
  if (-not $match.Success) { return '' }
  return (($match.Groups[2].Value -replace 'm','-') -replace 'p','.')
}

function Escape-GnuplotLabel([string]$Text) {
  return (($Text -replace '\\','/') -replace '"','\"')
}

function Write-ParamLabels([string]$Tag, [string[]]$HeaderLines, [string]$ParamPath) {
  if ($ParamPath -eq '') { return }

  $n1 = Get-TagValue $Tag 'N1'
  $n2 = Get-TagValue $Tag 'N2'
  $p11 = Get-TagValue $Tag 'P11'
  $p22 = Get-TagValue $Tag 'P22'
  $tmax = Get-TagValue $Tag 'TMAX'
  $b = Get-HeaderValue $HeaderLines 'b'
  $r = Get-HeaderValue $HeaderLines 'r'
  $e = Get-HeaderValue $HeaderLines 'e'
  $p12 = Get-HeaderValue $HeaderLines 'p12'
  $ndiv = Get-HeaderValue $HeaderLines 'ndiv'
  $nreps = Get-HeaderValue $HeaderLines 'n_reps'

  if ($b -eq '') { $b = Get-TagValue $Tag 'B' }
  if ($r -eq '') { $r = Get-TagValue $Tag 'R' }
  if ($e -eq '') { $e = Get-TagValue $Tag 'E' }
  if ($p12 -eq '') { $p12 = Get-TagValue $Tag 'P12' }

  $line1 = "N1=$n1, N2=$n2, b=$b, r=$r, e=$e"
  if ($tmax -ne '') {
    $line2 = "P11=$p11, P12=$p12, P22=$p22, T_MAX=$tmax, ndiv=$ndiv, reps=$nreps"
  } else {
    $line2 = "P11=$p11, P12=$p12, P22=$p22, ndiv=$ndiv, reps=$nreps"
  }

  @(
    'unset title'
    ('set title "' + (Escape-GnuplotLabel $line1) + '\n' + (Escape-GnuplotLabel $line2) + '" font "Times New Roman,16" tc rgb "#222222"')
  ) | Set-Content -Encoding ASCII -LiteralPath $ParamPath
}

if ($Infile -ne '') {
  if (!(Test-Path -LiteralPath $Infile)) {
    Write-Error "Input file not found: $Infile"
    exit 1
  }

  $headerLines = Get-Content -LiteralPath $Infile |
    Where-Object { $_ -like '#*' }

  Get-Content -LiteralPath $Infile |
    Where-Object { $_ -and $_[0] -ne '#' } |
    Set-Content -Encoding ASCII -LiteralPath $Points

  $header = $headerLines |
    Where-Object { $_ -like '# A:*' } |
    Select-Object -First 1

  $tag = [IO.Path]::GetFileNameWithoutExtension($Infile) -replace '^initial_plane__',''
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

  $headerLines = Get-Content -LiteralPath $parts[0].FullName |
    Where-Object { $_ -like '#*' }

  $parts | ForEach-Object {
    Get-Content -LiteralPath $_.FullName | Where-Object { $_ -and $_[0] -ne '#' }
  } | Set-Content -Encoding ASCII -LiteralPath $Points

  $header = $headerLines |
    Where-Object { $_ -like '# A:*' } |
    Select-Object -First 1

  $tag = Split-Path -Leaf $Indir
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

Write-ParamLabels $tag $headerLines $Params
