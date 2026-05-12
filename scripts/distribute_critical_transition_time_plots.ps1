param(
  [string]$Root = 'c_paper/out/experiments/03_critical_transition'
)

$ErrorActionPreference = 'Stop'

$rootPath = Resolve-Path $Root
$manifest = Join-Path $rootPath 'time_colored_initial_plane_plots.tsv'

if (-not (Test-Path -LiteralPath $manifest)) {
  throw "No encuentro el manifiesto: $manifest"
}

$rows = @(Import-Csv -LiteralPath $manifest -Delimiter "`t")
$groups = $rows | Group-Object {
  $data = $_.data -replace '/', '\'
  $rawDir = Split-Path -Parent $data
  Split-Path -Parent $rawDir
}

$copied = 0
$removed = 0

foreach ($group in $groups) {
  $experimentDir = $group.Name
  $plotDir = Join-Path $experimentDir 'plots'
  New-Item -ItemType Directory -Force -Path $plotDir | Out-Null

  $oldPngs = @(Get-ChildItem -LiteralPath $plotDir -Filter '*.png' -ErrorAction SilentlyContinue)
  foreach ($old in $oldPngs) {
    Remove-Item -LiteralPath $old.FullName -Force
    $removed++
  }

  $localManifest = Join-Path $plotDir 'time_colored_plots.tsv'
  "plot`tdata`tT_MAX`tcentral_plot" | Set-Content -LiteralPath $localManifest -Encoding ASCII

  foreach ($row in $group.Group) {
    if ($row.plot -match '/(ct[0-9]{3})_') {
      $localName = "$($Matches[1]).png"
    } else {
      $localName = [IO.Path]::GetFileName($row.plot)
    }

    $src = $row.plot -replace '/', '\'
    $dest = Join-Path $plotDir $localName
    Copy-Item -LiteralPath $src -Destination $dest -Force
    $copied++

    "$localName`t$($row.data)`t$($row.T_MAX)`t$($row.plot)" |
      Add-Content -LiteralPath $localManifest -Encoding ASCII
  }
}

Write-Host "PNG antiguos eliminados: $removed"
Write-Host "PNG nuevos distribuidos: $copied"
