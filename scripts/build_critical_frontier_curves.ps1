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
    if ($line -match '^#\s*T_MAX\s+([0-9]+)') { return [int]$Matches[1] }
  }
  if ($Fields.ContainsKey('TMAX')) { return [int](Convert-TagNumber $Fields['TMAX']) }
  if ($Path -match 'TMAX_([0-9]+)') { return [int]$Matches[1] }
  if ($Path -match 'TMAX([0-9]+)k') { return 1000 * [int]$Matches[1] }
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
  if ($n -eq 0) { return @([double]::NaN, [double]::NaN) }
  $sum = 0.0
  foreach ($v in $Values) { $sum += $v }
  $mean = $sum / $n
  if ($n -lt 2) { return @($mean, 0.0) }
  $ss = 0.0
  foreach ($v in $Values) {
    $d = $v - $mean
    $ss += $d * $d
  }
  return @($mean, [Math]::Sqrt(($ss / ($n - 1)) / $n))
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

  if ($n1 -ne 500 -or $n2 -ne 500) { continue }
  if ([Math]::Abs($p11 - $p22) -gt 1e-12) { continue }
  if ([Math]::Abs($b - 1.15) -gt 1e-12) { continue }
  if ([Math]::Abs($r) -gt 1e-12 -or [Math]::Abs($eps + 0.4) -gt 1e-12) { continue }

  $ePoint = Read-FixedPointE $file.FullName
  if ([double]::IsNaN($ePoint[0])) { continue }

  $distances = New-Object System.Collections.Generic.List[double]
  $times = New-Object System.Collections.Generic.List[double]
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
    if ($trelax -ge (0.999 * $tmax)) { $sat++ }
    $count++
  }
  if ($count -eq 0) { continue }

  $distStats = Get-MeanSem $distances.ToArray()
  $timeStats = Get-MeanSem $times.ToArray()

  $priority = $tmax + 10 * $reps
  if ($file.FullName -match 'statistics') { $priority += 1000000 }
  if ($file.FullName -match 'p_fine') { $priority += 100000 }
  if ($file.FullName -match 'frontier_scans_torre') { $priority += 10000 }
  if ($file.FullName -match 'connectivity_threshold') { $priority += 1000 }

  $key = '{0:F6}_{1:F6}' -f $p12, $p11
  $row = [pscustomobject]@{
    priority = $priority
    p11 = $p11
    p12 = $p12
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
    samples = $count
    source = $file.FullName
  }

  if (-not $rowsByKey.ContainsKey($key) -or $row.priority -gt $rowsByKey[$key].priority) {
    $rowsByKey[$key] = $row
  }
}

$allRows = $rowsByKey.Values | Sort-Object p12,p11
$curves = Join-Path $OutDir 'critical_frontier_curves.tsv'
"p11`tP12`tdist_E_mean`tdist_E_sem`ttrelax_norm_mean`ttrelax_norm_sem`tsat_frac`treps`tTMAX`tsamples`tsource" |
  Set-Content -LiteralPath $curves -Encoding ASCII

foreach ($row in $allRows) {
  $line = @($row.p11,$row.p12,$row.dist_E_mean,$row.dist_E_sem,$row.trelax_norm_mean,$row.trelax_norm_sem,$row.sat_frac,$row.reps,$row.tmax,$row.samples,$row.source) |
    ForEach-Object {
      if ($_ -is [double]) { $_.ToString('G12', [Globalization.CultureInfo]::InvariantCulture) } else { $_ }
    }
  ($line -join "`t") | Add-Content -LiteralPath $curves -Encoding ASCII
}

$frontier = Join-Path $OutDir 'critical_frontier_pc.tsv'
"P12`tpc`tmax_slope`tleft_p11`tright_p11`tleft_dist`tright_dist`tmean_trelax_norm`tmean_sat_frac`tn_points" |
  Set-Content -LiteralPath $frontier -Encoding ASCII

$groups = $allRows | Group-Object p12
foreach ($group in $groups) {
  $points = @($group.Group | Sort-Object p11)
  if ($points.Count -lt 3) { continue }

  $best = $null
  for ($i = 0; $i -lt ($points.Count - 1); $i++) {
    $left = $points[$i]
    $right = $points[$i + 1]
    $dp = $right.p11 - $left.p11
    if ($dp -le 0) { continue }
    $slope = [Math]::Abs(($right.dist_E_mean - $left.dist_E_mean) / $dp)
    if ($null -eq $best -or $slope -gt $best.slope) {
      $best = [pscustomobject]@{ slope=$slope; left=$left; right=$right }
    }
  }
  if ($null -eq $best) { continue }
  $pc = 0.5 * ($best.left.p11 + $best.right.p11)
  $mt = 0.5 * ($best.left.trelax_norm_mean + $best.right.trelax_norm_mean)
  $ms = 0.5 * ($best.left.sat_frac + $best.right.sat_frac)
  $line = @($points[0].p12,$pc,$best.slope,$best.left.p11,$best.right.p11,$best.left.dist_E_mean,$best.right.dist_E_mean,$mt,$ms,$points.Count) |
    ForEach-Object {
      if ($_ -is [double]) { $_.ToString('G12', [Globalization.CultureInfo]::InvariantCulture) } else { $_ }
    }
  ($line -join "`t") | Add-Content -LiteralPath $frontier -Encoding ASCII
}

Write-Host "Curvas escritas en $curves ($($allRows.Count) puntos)"
Write-Host "Frontera escrita en $frontier"
