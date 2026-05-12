param(
  [string]$Root = 'c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/asymmetry'
)

$ErrorActionPreference = 'Stop'
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Parse-DoubleInvariant([string]$Text) {
  return [double]::Parse($Text, $InvariantCulture)
}

function Get-TagValue([string]$Tag, [string]$Name) {
  $match = [regex]::Match($Tag, "(^|__)$Name`_([^_]+)")
  if (-not $match.Success) { return '' }
  return (($match.Groups[2].Value -replace 'm','-') -replace 'p','.')
}

function Get-HeaderValue([string[]]$Lines, [string]$Name) {
  $line = $Lines | Where-Object { $_ -match "^\s*#\s+$Name\s+" } | Select-Object -First 1
  if (-not $line) { return '' }
  return (($line -replace "^\s*#\s+$Name\s+", '')).Trim()
}

function Get-Param([string]$Tag, [string[]]$HeaderLines, [string]$HeaderName, [string]$TagName) {
  $value = Get-HeaderValue $HeaderLines $HeaderName
  if ($value -eq '') { $value = Get-TagValue $Tag $TagName }
  return $value
}

function Add-PhysicalPoint([System.Collections.ArrayList]$Points, [double]$X1, [double]$X2) {
  $tol = 1e-9
  if ($X1 -ge -$tol -and $X1 -le 1.0 + $tol -and $X2 -ge -$tol -and $X2 -le 1.0 + $tol) {
    [void]$Points.Add([pscustomobject]@{
      x1 = [Math]::Min(1.0, [Math]::Max(0.0, $X1))
      x2 = [Math]::Min(1.0, [Math]::Max(0.0, $X2))
    })
  }
}

function Get-FixedPoints([double]$N1, [double]$N2, [double]$P12, [double]$B, [double]$R, [double]$Eps) {
  $rho = $N1 / $N2
  $a12 = $P12 / $rho
  $a21 = $P12 * $rho
  $d = $B - 1.0 - $R
  $h = $B - 1.0 - $Eps
  $den = $P12 * $P12 * $h * $h - $d * $d
  $tol = 1e-12
  $points = [System.Collections.ArrayList]::new()
  Add-PhysicalPoint $points 0.0 1.0
  Add-PhysicalPoint $points 1.0 0.0
  Add-PhysicalPoint $points 1.0 1.0
  Add-PhysicalPoint $points 0.0 0.0
  if ([Math]::Abs($d) -gt $tol) {
    Add-PhysicalPoint $points 0.0 (-($R + $a21 * $Eps) / $d)
    Add-PhysicalPoint $points (-($R + $a12 * $Eps) / $d) 0.0
  }
  if ([Math]::Abs($den) -gt $tol) {
    $e0 = ($d * ($R + $a12 * $Eps) - $a12 * $h * ($R + $a21 * $Eps)) / $den
    $e1 = ($d * ($R + $a21 * $Eps) - $a21 * $h * ($R + $a12 * $Eps)) / $den
    Add-PhysicalPoint $points $e0 $e1
  }
  return $points
}

function MeanAndSem([double[]]$Values) {
  $n = $Values.Count
  if ($n -eq 0) { return @(0.0, 0.0) }
  $mean = ($Values | Measure-Object -Average).Average
  if ($n -lt 2) { return @($mean, 0.0) }
  $sum2 = 0.0
  foreach ($v in $Values) { $sum2 += ($v - $mean) * ($v - $mean) }
  return @($mean, [Math]::Sqrt(($sum2 / ($n - 1)) / $n))
}

$outDir = Join-Path $Root 'summary_plots'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$summary = Join-Path $outDir 'asymmetry_distance_summary.tsv'
"family`tN1`tN2`tNtot`trho`tabs_log_rho`tB`tP12`tP11`tP22`tk_mean`tdmin_mean`tdmin_sem`ttrelax_norm_mean`tn`tfile" |
  Set-Content -Encoding ASCII -LiteralPath $summary

Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'initial_plane__*.txt' |
  Sort-Object FullName |
  ForEach-Object {
    $file = $_
    $family = Split-Path (Split-Path $file.DirectoryName -Parent) -Leaf
    if ($file.DirectoryName -notmatch '\\raw$') { return }
    $tag = [IO.Path]::GetFileNameWithoutExtension($file.Name) -replace '^initial_plane__',''
    $header = Get-Content -LiteralPath $file.FullName -TotalCount 80 | Where-Object { $_ -like '#*' }

    $n1 = Parse-DoubleInvariant (Get-Param $tag $header 'N1' 'N1')
    $n2 = Parse-DoubleInvariant (Get-Param $tag $header 'N2' 'N2')
    $p11 = Parse-DoubleInvariant (Get-Param $tag $header 'P11' 'P11')
    $p12 = Parse-DoubleInvariant (Get-Param $tag $header 'p12' 'P12')
    $p22 = Parse-DoubleInvariant (Get-Param $tag $header 'P22' 'P22')
    $b = Parse-DoubleInvariant (Get-Param $tag $header 'b' 'B')
    $r = Parse-DoubleInvariant (Get-Param $tag $header 'r' 'R')
    $eps = Parse-DoubleInvariant (Get-Param $tag $header 'e' 'E')
    $tmaxText = Get-Param $tag $header 'T_MAX' 'TMAX'
    if ($tmaxText -eq '') { $tmaxText = '30000' }
    $tmax = Parse-DoubleInvariant $tmaxText

    $fixed = Get-FixedPoints $n1 $n2 $p12 $b $r $eps
    $distances = New-Object System.Collections.Generic.List[double]
    $times = New-Object System.Collections.Generic.List[double]

    Get-Content -LiteralPath $file.FullName |
      Where-Object { $_ -and $_[0] -ne '#' } |
      ForEach-Object {
        $cols = $_ -split "\s+"
        if ($cols.Count -lt 10) { return }
        $x1 = Parse-DoubleInvariant $cols[5]
        $x2 = Parse-DoubleInvariant $cols[6]
        $best = [double]::PositiveInfinity
        foreach ($fp in $fixed) {
          $d = [Math]::Sqrt(($x1 - $fp.x1) * ($x1 - $fp.x1) + ($x2 - $fp.x2) * ($x2 - $fp.x2))
          if ($d -lt $best) { $best = $d }
        }
        $distances.Add($best)
        $times.Add((Parse-DoubleInvariant $cols[9]) / $tmax)
      }

    $dStats = MeanAndSem $distances.ToArray()
    $tStats = MeanAndSem $times.ToArray()
    $rho = $n1 / $n2
    $kMean = 0.5 * ($p11 * ($n1 - 1.0) + $p22 * ($n2 - 1.0))
    [string]::Format(
      $InvariantCulture,
      "{0}`t{1:g}`t{2:g}`t{3:g}`t{4:0.############}`t{5:0.############}`t{6:g}`t{7:g}`t{8:g}`t{9:g}`t{10:0.############}`t{11:0.############}`t{12:0.############}`t{13:0.############}`t{14}`t{15}",
      $family, $n1, $n2, ($n1 + $n2), $rho, [Math]::Abs([Math]::Log($rho)),
      $b, $p12, $p11, $p22, $kMean, $dStats[0], $dStats[1], $tStats[0], $distances.Count,
      $file.FullName.Replace('\','/')
    ) | Add-Content -Encoding ASCII -LiteralPath $summary
  }

Write-Host "Resumen escrito en $summary"
