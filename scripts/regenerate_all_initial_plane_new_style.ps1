param(
  [string]$Root = 'c_paper/out/experiments'
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

  $full = $Path -replace '\\','/'
  if ($full -match 'TMAX_([0-9]+)') {
    return [int]$Matches[1]
  }
  if ($full -match 'T([0-9]+)k') {
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

  $bits = @("ip{0:D3}" -f $Index)
  foreach ($key in @('N1', 'N2', 'P11', 'P12', 'P22', 'B', 'TMAX')) {
    if ($fields.ContainsKey($key)) {
      $bits += "$key$($fields[$key])"
    }
  }
  return (($bits -join '_') + '.png')
}

function Read-ExistingPlotMap {
  param([string]$PlotDir)

  $map = @{}
  $manifest = Join-Path $PlotDir 'time_colored_plots.tsv'
  if (-not (Test-Path -LiteralPath $manifest)) {
    return $map
  }

  Get-Content -LiteralPath $manifest | Select-Object -Skip 1 | ForEach-Object {
    if (-not $_) { return }
    $cols = $_ -split "`t"
    if ($cols.Count -lt 2) { return }
    $plotName = [IO.Path]::GetFileName($cols[0])
    $dataName = [IO.Path]::GetFileName($cols[1])
    if ($plotName -and $dataName) {
      $map[$dataName] = $plotName
    }
  }

  return $map
}

$rootPath = Resolve-Path $Root
$files = @(Get-ChildItem -LiteralPath $rootPath -Recurse -Filter 'initial_plane__*.txt' |
  Where-Object {
    $_.FullName -match '\\raw\\' -and
    $_.Name -notmatch '\._' -and
    $_.Length -gt 0
  } |
  Sort-Object FullName)

if ($files.Count -eq 0) {
  Write-Host "No encuentro raw initial_plane bajo $Root"
  exit 0
}

$groups = $files | Group-Object { Split-Path -Parent $_.FullName }
$ok = 0
$failed = 0

foreach ($group in $groups) {
  $rawDir = $group.Name
  $experimentDir = Split-Path -Parent $rawDir
  $plotDir = Join-Path $experimentDir 'plots'
  New-Item -ItemType Directory -Force -Path $plotDir | Out-Null

  $existingMap = Read-ExistingPlotMap $plotDir
  $manifest = Join-Path $plotDir 'initial_plane_new_style_plots.tsv'
  "plot`tdata`tT_MAX" | Set-Content -LiteralPath $manifest -Encoding ASCII

  $groupFiles = @($group.Group | Sort-Object FullName)
  for ($i = 0; $i -lt $groupFiles.Count; $i++) {
    $file = $groupFiles[$i]
    $plotName = $null
    if ($existingMap.ContainsKey($file.Name)) {
      $plotName = $existingMap[$file.Name]
    } else {
      $candidate = $file.BaseName + '.png'
      $candidatePath = Join-Path $plotDir $candidate
      if ($candidatePath.Length -lt 220) {
        $plotName = $candidate
      } else {
        $plotName = Get-CompactPlotName $file ($i + 1)
      }
    }

    $out = Join-Path $plotDir $plotName
    #
    #if ($out.Length -ge 220) {
     # $plotName = "ip{0:D3}.png" -f ($i + 1)
      #$out = Join-Path $plotDir $plotName
    #}
    #
    $tmax = Read-TMax $file.FullName
    $inGp = Get-RelativeGnuplotPath $file.FullName
    $outGp = Get-RelativeGnuplotPath $out

    if ($null -eq $tmax) {
      $expr = "infile='$inGp'; outfile='$outGp'"
    } else {
      $expr = "tmax=$tmax; infile='$inGp'; outfile='$outGp'"
    }

    Write-Host "plot $($file.FullName.Substring($rootPath.Path.Length + 1)) -> $plotName"
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
}

Write-Host "Plots generados: $ok"
if ($failed -gt 0) {
  Write-Host "Fallos: $failed"
  exit 1
}
