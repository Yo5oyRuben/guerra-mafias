param(
  [string]$Root = 'c_paper/out/experiments/03_critical_transition'
)

$ErrorActionPreference = 'Stop'

$rootPath = Resolve-Path $Root
$repo = Resolve-Path '.'
$manifest = Join-Path $rootPath 'time_colored_initial_plane_plots.tsv'

function Get-RelativePathText {
  param([string]$Path)
  $repoPath = [System.IO.Path]::GetFullPath($repo.Path)
  $fullPath = [System.IO.Path]::GetFullPath($Path)
  if (-not $repoPath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
    $repoPath += [System.IO.Path]::DirectorySeparatorChar
  }
  $repoUri = New-Object System.Uri($repoPath)
  $fileUri = New-Object System.Uri($fullPath)
  return [System.Uri]::UnescapeDataString($repoUri.MakeRelativeUri($fileUri).ToString()) -replace '/', '\'
}

"plot`tdata`tT_MAX" | Set-Content -LiteralPath $manifest -Encoding ASCII

$localManifests = @(Get-ChildItem -LiteralPath $rootPath -Recurse -Filter 'time_colored_plots.tsv' |
  Sort-Object FullName)

foreach ($localManifest in $localManifests) {
  $plotDir = $localManifest.Directory.FullName
  $rows = @(Import-Csv -LiteralPath $localManifest.FullName -Delimiter "`t")
  foreach ($row in $rows) {
    $plotPath = Join-Path $plotDir $row.plot
    $plotRel = Get-RelativePathText $plotPath
    "$plotRel`t$($row.data)`t$($row.T_MAX)" | Add-Content -LiteralPath $manifest -Encoding ASCII
  }
}

Write-Host "Manifiesto global actualizado: $($localManifests.Count) carpetas"
