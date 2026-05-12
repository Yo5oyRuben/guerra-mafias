param(
  [string]$OutDir = 'c_paper/out/experiments/03_critical_transition/summary_plots'
)

$ErrorActionPreference = 'Stop'

function Convert-TagNumber {
  param([string]$Text)
  $s = $Text -replace '^m','-' -replace 'p','.'
  return [double]::Parse($s, [Globalization.CultureInfo]::InvariantCulture)
}

function Get-FieldMap {
  param([string]$Name)
  $fields = @{}
  foreach ($part in ($Name -split '__')) {
    if ($part -match '^([A-Z0-9]+)_(.+)$') {
      $fields[$Matches[1]] = $Matches[2]
    }
  }
  return $fields
}

function Read-TMax {
  param([string]$Path, [hashtable]$Fields)

  foreach ($line in Get-Content -LiteralPath $Path -TotalCount 80) {
    if ($line -match '^#\s*T_MAX\s+([0-9]+)') {
      return [int]$Matches[1]
    }
  }
  if ($Fields.ContainsKey('TMAX')) {
    return [int](Convert-TagNumber $Fields['TMAX'])
  }
  if ($Path -match 'TMAX_([0-9]+)') {
    return [int]$Matches[1]
  }
  if ($Path -match 'TMAX([0-9]+)k') {
    return 1000 * [int]$Matches[1]
  }

  return 400000
}

function Read-FixedPointE {
  param([string]$Path)

  foreach ($line in Get-Content -LiteralPath $Path -TotalCount 30) {
    if ($line -match 'E:\(([0-9eE+\-.]+),([0-9eE+\-.]+)\)') {
      return @(
        [double]::Parse($Matches[1], [Globalization.CultureInfo]::InvariantCulture),
        [double]::Parse($Matches[2], [Globalization.CultureInfo]::InvariantCulture)
      )
    }
  }
  return @([double]::NaN, [double]::NaN)
}

function Get-MeanSem {
  param([double[]]$Values)

  $n = $Values.Count
  if ($n -eq 0) {
    return @([double]::NaN, [double]::NaN)
  }

  $sum = 0.0
  foreach ($v in $Values) { $sum += $v }
  $mean = $sum / $n

  if ($n -lt 2) {
    return @($mean, 0.0)
  }

  $ss = 0.0
  foreach ($v in $Values) {
    $d = $v - $mean
    $ss += $d * $d
  }
  $sem = [Math]::Sqrt(($ss / ($n - 1)) / $n)
  return @($mean, $sem)
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$roots = @(
  'c_paper/out/experiments/03_critical_transition',
  'c_paper/out/experiments/02_thermodynamic_limit_high_connectivity/connectivity_threshold'
)

$files = @()
foreach ($root in $roots) {
  if (Test-Path -LiteralPath $root) {
    $files += Get-ChildItem -LiteralPath $root -Recurse -Filter 'initial_plane__*.txt' |
      Where-Object { $_.FullName -match '\\raw\\' -and $_.FullName -notmatch '\._' }
  }
}

$rowsByKey = @{}
foreach ($file in $files) {
  $fields = Get-FieldMap $file.BaseName
  foreach ($required in @('N1', 'N2', 'P11', 'P12', 'P22', 'B', 'R', 'E')) {
    if (-not $fields.ContainsKey($required)) { continue }
  }

  $n1 = [int](Convert-TagNumber $fields['N1'])
  $n2 = [int](Convert-TagNumber $fields['N2'])
  $p11 = Convert-TagNumber $fields['P11']
  $p12 = Convert-TagNumber $fields['P12']
  $p22 = Convert-TagNumber $fields['P22']
  $b = Convert-TagNumber $fields['B']
  $r = Convert-TagNumber $fields['R']
  $eps = Convert-TagNumber $fields['E']
  $ndiv = if ($fields.ContainsKey('ndiv')) { [int](Convert-TagNumber $fields['ndiv']) } else { 0 }
  $reps = if ($fields.ContainsKey('reps')) { [int](Convert-TagNumber $fields['reps']) } else { 0 }
  $tmax = Read-TMax $file.FullName $fields
  $ePoint = Read-FixedPointE $file.FullName

  if ($n1 -ne 500 -or $n2 -ne 500) { continue }
  if ([Math]::Abs($p11 - $p22) -gt 1e-12) { continue }
  if ([Math]::Abs($p12 - 0.20) -gt 1e-12) { continue }
  if ([Math]::Abs($b - 1.15) -gt 1e-12) { continue }
  if ([double]::IsNaN($ePoint[0])) { continue }

  $distances = New-Object System.Collections.Generic.List[double]
  $times = New-Object System.Collections.Generic.List[double]
  $x1Values = New-Object System.Collections.Generic.List[double]
  $x2Values = New-Object System.Collections.Generic.List[double]
  $sat = 0
  $count = 0

  foreach ($line in Get-Content -LiteralPath $file.FullName) {
    if ($line.StartsWith('#') -or $line.Trim().Length -eq 0) { continue }
    $parts = $line -split '\s+'
    if ($parts.Count -lt 10) { continue }

    $x1 = [double]::Parse($parts[5], [Globalization.CultureInfo]::InvariantCulture)
    $x2 = [double]::Parse($parts[6], [Globalization.CultureInfo]::InvariantCulture)
    $trelax = [double]::Parse($parts[9], [Globalization.CultureInfo]::InvariantCulture)
    $dx = $x1 - $ePoint[0]
    $dy = $x2 - $ePoint[1]

    $distances.Add([Math]::Sqrt($dx * $dx + $dy * $dy))
    $times.Add($trelax / $tmax)
    $x1Values.Add($x1)
    $x2Values.Add($x2)
    if ($trelax -ge (0.999 * $tmax)) { $sat++ }
    $count++
  }

  if ($count -eq 0) { continue }

  $distStats = Get-MeanSem $distances.ToArray()
  $timeStats = Get-MeanSem $times.ToArray()
  $x1Stats = Get-MeanSem $x1Values.ToArray()
  $x2Stats = Get-MeanSem $x2Values.ToArray()

  $priority = 0
  if ($file.FullName -match 'statistics') { $priority += 1000000 }
  if ($file.FullName -match 'p_fine') { $priority += 100000 }
  if ($file.FullName -match 'connectivity_threshold') { $priority += 1000 }
  $priority += $tmax + 10 * $reps

  $key = '{0:F6}_{1:F6}_{2:F6}_{3:F6}_{4:F6}' -f $p11, $p12, $b, $r, $eps
  $row = [pscustomobject]@{
    priority = $priority
    p11 = $p11
    p12 = $p12
    b = $b
    r = $r
    eps = $eps
    n1 = $n1
    n2 = $n2
    ndiv = $ndiv
    reps = $reps
    tmax = $tmax
    e_x = $ePoint[0]
    e_y = $ePoint[1]
    dist_E_mean = $distStats[0]
    dist_E_sem = $distStats[1]
    trelax_norm_mean = $timeStats[0]
    trelax_norm_sem = $timeStats[1]
    sat_frac = $sat / $count
    x1_mean = $x1Stats[0]
    x2_mean = $x2Stats[0]
    samples = $count
    source = $file.FullName
  }

  if (-not $rowsByKey.ContainsKey($key) -or $row.priority -gt $rowsByKey[$key].priority) {
    $rowsByKey[$key] = $row
  }
}

$summary = Join-Path $OutDir 'critical_phase_transition_summary.tsv'
$selected = $rowsByKey.Values |
  Where-Object {
    -not (
      $_.source -match 'connectivity_threshold' -and
      $_.p11 -gt 0.70 -and
      $_.p11 -lt 0.80
    )
  } |
  Sort-Object p11

"p11`tP12`tB`tR`tEpay`tN1`tN2`tndiv`treps`tTMAX`txE`tyE`tdist_E_mean`tdist_E_sem`ttrelax_norm_mean`ttrelax_norm_sem`tsat_frac`tx1_mean`tx2_mean`tsamples`tsource" |
  Set-Content -LiteralPath $summary -Encoding ASCII

foreach ($row in $selected) {
  $line = @(
    $row.p11, $row.p12, $row.b, $row.r, $row.eps, $row.n1, $row.n2, $row.ndiv,
    $row.reps, $row.tmax, $row.e_x, $row.e_y, $row.dist_E_mean, $row.dist_E_sem,
    $row.trelax_norm_mean, $row.trelax_norm_sem, $row.sat_frac, $row.x1_mean,
    $row.x2_mean, $row.samples, $row.source
  ) | ForEach-Object {
    if ($_ -is [double]) { $_.ToString('G12', [Globalization.CultureInfo]::InvariantCulture) } else { $_ }
  }
  ($line -join "`t") | Add-Content -LiteralPath $summary -Encoding ASCII
}

Write-Host "Resumen escrito en $summary ($($selected.Count) puntos)"
