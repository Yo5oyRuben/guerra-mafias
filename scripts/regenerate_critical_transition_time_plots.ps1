param(
  [string]$Root = 'c_paper/out/experiments/03_critical_transition'
)

$ErrorActionPreference = 'Stop'

function Read-TMax {
  param([string]$Path)

  foreach ($line in Get-Content -LiteralPath $Path -TotalCount 80) {
    if ($line -match '^#\s*T_MAX\s+([0-9]+)') {
      return [int]$Matches[1]
    }
  }

  $name = [IO.Path]::GetFileNameWithoutExtension($Path)
  if ($name -match 'TMAX_([0-9]+)') {
    return [int]$Matches[1]
  }
  if ($name -match 'TMAX([0-9]+)k') {
    return 1000 * [int]$Matches[1]
  }

  return $null
}

function Quote-GnuplotPath {
  param([string]$Path)
  return ($Path -replace '\\','/') -replace "'","''"
}

$repo = Resolve-Path '.'

function Get-RelativeGnuplotPath {
  param([string]$Path)
  $repoPath = [System.IO.Path]::GetFullPath($repo.Path)
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not $repoPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $repoPath += [System.IO.Path]::DirectorySeparatorChar
  }
  $repoUri = New-Object System.Uri($repoPath)
  $fileUri = New-Object System.Uri($fullPath)
  $relative = [System.Uri]::UnescapeDataString($repoUri.MakeRelativeUri($fileUri).ToString())
  return Quote-GnuplotPath $relative
}

function Get-CompactPlotName {
  param(
    [System.IO.FileInfo]$File,
    [int]$Index
  )

  $name = $File.BaseName
  $fields = @{}
  foreach ($part in ($name -split '__')) {
    if ($part -match '^([A-Z0-9]+)_(.+)$') {
      $fields[$Matches[1]] = $Matches[2]
    }
  }

  $bits = @("ct{0:D3}" -f $Index)
  foreach ($key in @('N1', 'N2', 'P11', 'P12', 'P22', 'B', 'TMAX')) {
    if ($fields.ContainsKey($key)) {
      $bits += "$key$($fields[$key])"
    }
  }
  return (($bits -join '_') + '.png')
}

$rootPath = Resolve-Path $Root
$files = @(Get-ChildItem -LiteralPath $rootPath -Recurse -Filter 'initial_plane__*.txt' |
  Where-Object { $_.FullName -match '\\raw\\' } |
  Sort-Object FullName)

if ($files.Count -eq 0) {
  Write-Host "No encuentro raw initial_plane bajo $Root"
  exit 0
}

$ok = 0
$failed = 0
$manifest = Join-Path $rootPath 'time_colored_initial_plane_plots.tsv'
"plot`tdata`tT_MAX" | Set-Content -LiteralPath $manifest -Encoding ASCII
$centralPlotDir = Join-Path $rootPath 'plots_time_colored'
New-Item -ItemType Directory -Force -Path $centralPlotDir | Out-Null

for ($i = 0; $i -lt $files.Count; $i++) {
  $file = $files[$i]
  $out = Join-Path $centralPlotDir (Get-CompactPlotName $file ($i + 1))
  $tmax = Read-TMax $file.FullName
  $inGp = Get-RelativeGnuplotPath $file.FullName
  $outGp = Get-RelativeGnuplotPath $out

  if ($null -eq $tmax) {
    $expr = "infile='$inGp'; outfile='$outGp'"
  } else {
    $expr = "tmax=$tmax; infile='$inGp'; outfile='$outGp'"
  }

  Write-Host "plot $($file.FullName.Substring($rootPath.Path.Length + 1))"
  & gnuplot -e $expr c_paper/out/gp/plot_initial_plane.gp
  if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $out)) {
    $ok++
    $plotRel = Get-RelativeGnuplotPath $out
    $dataRel = Get-RelativeGnuplotPath $file.FullName
    "$plotRel`t$dataRel`t$tmax" | Add-Content -LiteralPath $manifest -Encoding ASCII
  } else {
    Write-Warning "Fallo plot: $($file.FullName)"
    $failed++
  }
}

Write-Host "Plots generados: $ok"
if ($failed -gt 0) {
  Write-Host "Fallos: $failed"
  exit 1
}
