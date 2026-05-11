param(
  [switch]$Apply
)

$ErrorActionPreference = 'Stop'

$Root = Resolve-Path 'c_paper/out/experiments'
$RootPath = [System.IO.Path]::GetFullPath($Root.Path)
$Active = 'degree_linear_overnight_fig3_thermo_2026-05-11_real'

function Assert-UnderRoot {
  param([string]$Path)
  $full = [System.IO.Path]::GetFullPath($Path)
  if (-not $full.StartsWith($RootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Ruta fuera de experiments: $full"
  }
  return $full
}

function Has-ExperimentMarker {
  param([string]$Path)
  foreach ($name in @('raw','plots','logs','parts','manifest.tsv','notes.md','controller.log')) {
    if (Test-Path -LiteralPath (Join-Path $Path $name)) {
      return $true
    }
  }
  return $false
}

function Is-UnderExperiment {
  param([System.IO.DirectoryInfo]$Dir)
  $current = $Dir.Parent
  while ($null -ne $current -and $current.FullName.Length -ge $RootPath.Length) {
    if (Has-ExperimentMarker $current.FullName) {
      return $true
    }
    if ($current.FullName -ieq $RootPath) {
      break
    }
    $current = $current.Parent
  }
  return $false
}

function Get-Candidates {
  $dirs = Get-ChildItem -LiteralPath $RootPath -Directory -Recurse |
    Where-Object {
      $_.FullName -notlike "*\$Active*" -and
      $_.Name -notin @('raw','plots','logs','parts','build') -and
      -not (Is-UnderExperiment $_)
    } |
    Sort-Object { $_.FullName.Length } -Descending

  foreach ($parent in $dirs) {
    $childDirs = @(Get-ChildItem -LiteralPath $parent.FullName -Directory -Force |
      Where-Object { $_.Name -ne '.git' })
    $meaningfulFiles = @(Get-ChildItem -LiteralPath $parent.FullName -File -Force |
      Where-Object { $_.Name -notin @('.syncmetadata','README.md') })

    if ($childDirs.Count -ne 1 -or $meaningfulFiles.Count -ne 0) {
      continue
    }

    $child = $childDirs[0]
    if (-not (Has-ExperimentMarker $child.FullName)) {
      continue
    }

    [pscustomobject]@{
      Parent = $parent.FullName
      Child = $child.FullName
      ParentRel = $parent.FullName.Substring($RootPath.Length + 1)
      ChildName = $child.Name
    }
  }
}

$candidates = @(Get-Candidates)
if ($candidates.Count -eq 0) {
  Write-Host "No hay wrappers de experimento de una sola carpeta para aplanar."
  exit 0
}

foreach ($candidate in $candidates) {
  $parent = Assert-UnderRoot $candidate.Parent
  $child = Assert-UnderRoot $candidate.Child
  Write-Host ("{0}\{1} -> {0}" -f $candidate.ParentRel, $candidate.ChildName)

  if ($Apply) {
    foreach ($item in Get-ChildItem -LiteralPath $child -Force) {
      $dest = Join-Path $parent $item.Name
      if (Test-Path -LiteralPath $dest) {
        if ($item.Name -eq '.syncmetadata') {
          continue
        }
        throw "No puedo aplanar; ya existe destino: $dest"
      }
      Move-Item -LiteralPath $item.FullName -Destination $dest
    }
    Remove-Item -LiteralPath $child -Force -Recurse
  }
}
