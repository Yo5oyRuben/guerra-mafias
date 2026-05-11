param(
  [string]$Indir = '',
  [string]$Infile = '',
  [Parameter(Mandatory=$true)][string]$Points,
  [string]$InitialAvg = '',
  [string]$Nullcline1 = '',
  [string]$Nullcline2 = '',
  [Parameter(Mandatory=$true)][string]$Fixed,
  [string]$FixedStable = '',
  [string]$Params = '',
  [string]$TmaxLabel = '',
  [Parameter(Mandatory=$true)][string]$PlotDir
)

New-Item -ItemType Directory -Force -Path $PlotDir | Out-Null
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

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

function Parse-DoubleInvariant([string]$Text) {
  return [double]::Parse($Text, $InvariantCulture)
}

function Write-ParamLabels([string]$Tag, [string[]]$HeaderLines, [string]$ParamPath) {
  if ($ParamPath -eq '') { return }

  $n1 = Get-TagValue $Tag 'N1'
  $n2 = Get-TagValue $Tag 'N2'
  $p11 = Get-TagValue $Tag 'P11'
  $p22 = Get-TagValue $Tag 'P22'
  $tmax = Get-HeaderValue $HeaderLines 'T_MAX'
  if ($tmax -eq '') { $tmax = Get-TagValue $Tag 'TMAX' }
  if ($tmax -eq '') { $tmax = $TmaxLabel }
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
    $line2 = "P11=$p11, P12=$p12, P22=$p22, T_{MAX}=$tmax, ndiv=$ndiv, reps=$nreps"
  } else {
    $line2 = "P11=$p11, P12=$p12, P22=$p22, ndiv=$ndiv, reps=$nreps"
  }

  @(
    'unset title'
    ('set title "' + (Escape-GnuplotLabel $line1) + '\n' + (Escape-GnuplotLabel $line2) + '" font "Times New Roman,16" tc rgb "#222222"')
  ) | Set-Content -Encoding ASCII -LiteralPath $ParamPath
}

function Get-ParameterValue {
  param([string]$Tag, [string[]]$HeaderLines, [string]$HeaderName, [string]$TagName)
  $value = Get-HeaderValue $HeaderLines $HeaderName
  if ($value -eq '') { $value = Get-TagValue $Tag $TagName }
  return $value
}

function Get-JacobianClass {
  param(
    [double]$X1,
    [double]$X2,
    [double]$B,
    [double]$Beta,
    [double]$R,
    [double]$P,
    [double]$Eps
  )

  $A = 1.0 - $B + $R
  $C = 1.0 - $B + $Eps
  $g1 = $Beta * ($X1 * $A - $R) + $P * ($X2 * $C - $Eps)
  $g2 = ($X2 * $A - $R) + $Beta * $P * ($X1 * $C - $Eps)

  $j11 = (1.0 - 2.0 * $X1) * $g1 + $X1 * (1.0 - $X1) * $Beta * $A
  $j12 = $X1 * (1.0 - $X1) * $P * $C
  $j21 = $X2 * (1.0 - $X2) * $Beta * $P * $C
  $j22 = (1.0 - 2.0 * $X2) * $g2 + $X2 * (1.0 - $X2) * $A

  $trace = $j11 + $j22
  $det = $j11 * $j22 - $j12 * $j21
  $tol = 1e-9

  if ($det -lt -$tol) { return 'saddle' }
  if ($det -gt $tol -and $trace -lt -$tol) { return 'stable' }
  if ($det -gt $tol -and $trace -gt $tol) { return 'unstable' }
  return 'marginal'
}

function Write-FixedPointStability {
  param(
    [string]$FixedPath,
    [string]$StablePath,
    [string]$Tag,
    [string[]]$HeaderLines
  )

  if ($StablePath -eq '') { return }

  $bText = Get-ParameterValue $Tag $HeaderLines 'b' 'B'
  $rText = Get-ParameterValue $Tag $HeaderLines 'r' 'R'
  $eText = Get-ParameterValue $Tag $HeaderLines 'e' 'E'
  $pText = Get-ParameterValue $Tag $HeaderLines 'p12' 'P12'
  $n1Text = Get-ParameterValue $Tag $HeaderLines 'N1' 'N1'
  $n2Text = Get-ParameterValue $Tag $HeaderLines 'N2' 'N2'

  if ($bText -eq '' -or $rText -eq '' -or $eText -eq '' -or $pText -eq '' -or
      $n1Text -eq '' -or $n2Text -eq '') {
    Copy-Item -LiteralPath $FixedPath -Destination $StablePath -Force
    return
  }

  $b = Parse-DoubleInvariant $bText
  $r = Parse-DoubleInvariant $rText
  $eps = Parse-DoubleInvariant $eText
  $p = Parse-DoubleInvariant $pText
  $beta = (Parse-DoubleInvariant $n1Text) / (Parse-DoubleInvariant $n2Text)

  Get-Content -LiteralPath $FixedPath |
    ForEach-Object {
      $cols = $_ -split "\s+"
      if ($cols.Count -lt 3) { return }
      $label = $cols[0]
      $x1 = Parse-DoubleInvariant $cols[1]
      $x2 = Parse-DoubleInvariant $cols[2]
      $class = Get-JacobianClass $x1 $x2 $b $beta $r $p $eps
      [string]::Format($InvariantCulture, "{0} {1:F12} {2:F12} {3}", $label, $x1, $x2, $class)
    } |
    Set-Content -Encoding ASCII -LiteralPath $StablePath
}

function Write-Nullclines {
  param(
    [string]$Nullcline1Path,
    [string]$Nullcline2Path,
    [string]$Tag,
    [string[]]$HeaderLines
  )

  if ($Nullcline1Path -eq '' -and $Nullcline2Path -eq '') { return }

  $bText = Get-ParameterValue $Tag $HeaderLines 'b' 'B'
  $rText = Get-ParameterValue $Tag $HeaderLines 'r' 'R'
  $eText = Get-ParameterValue $Tag $HeaderLines 'e' 'E'
  $pText = Get-ParameterValue $Tag $HeaderLines 'p12' 'P12'
  $n1Text = Get-ParameterValue $Tag $HeaderLines 'N1' 'N1'
  $n2Text = Get-ParameterValue $Tag $HeaderLines 'N2' 'N2'

  if ($bText -eq '' -or $rText -eq '' -or $eText -eq '' -or $pText -eq '' -or
      $n1Text -eq '' -or $n2Text -eq '') {
    if ($Nullcline1Path -ne '') { '' | Set-Content -Encoding ASCII -LiteralPath $Nullcline1Path }
    if ($Nullcline2Path -ne '') { '' | Set-Content -Encoding ASCII -LiteralPath $Nullcline2Path }
    return
  }

  $b = Parse-DoubleInvariant $bText
  $r = Parse-DoubleInvariant $rText
  $eps = Parse-DoubleInvariant $eText
  $p = Parse-DoubleInvariant $pText
  $beta = (Parse-DoubleInvariant $n1Text) / (Parse-DoubleInvariant $n2Text)

  $a = 1.0 - $b + $r
  $c = 1.0 - $b + $eps
  $tol = 1e-12
  $n = 400

  if ($Nullcline1Path -ne '') {
    $rows = New-Object System.Collections.Generic.List[string]
    if ([Math]::Abs($p * $c) -gt $tol) {
      for ($i = 0; $i -le $n; $i++) {
        $x1 = [double]$i / [double]$n
        $x2 = ($beta * $r + $p * $eps - $beta * $a * $x1) / ($p * $c)
        if ($x2 -ge 0.0 -and $x2 -le 1.0) {
          $rows.Add([string]::Format($InvariantCulture, "{0:F12} {1:F12}", $x1, $x2))
        } elseif ($rows.Count -gt 0 -and $rows[$rows.Count - 1] -ne '') {
          $rows.Add('')
        }
      }
    }
    $rows | Set-Content -Encoding ASCII -LiteralPath $Nullcline1Path
  }

  if ($Nullcline2Path -ne '') {
    $rows = New-Object System.Collections.Generic.List[string]
    if ([Math]::Abs($a) -gt $tol) {
      for ($i = 0; $i -le $n; $i++) {
        $x1 = [double]$i / [double]$n
        $x2 = ($r + $beta * $p * $eps - $beta * $p * $c * $x1) / $a
        if ($x2 -ge 0.0 -and $x2 -le 1.0) {
          $rows.Add([string]::Format($InvariantCulture, "{0:F12} {1:F12}", $x1, $x2))
        } elseif ($rows.Count -gt 0 -and $rows[$rows.Count - 1] -ne '') {
          $rows.Add('')
        }
      }
    }
    $rows | Set-Content -Encoding ASCII -LiteralPath $Nullcline2Path
  }
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

if ($InitialAvg -ne '') {
  $acc = @{}
  Get-Content -LiteralPath $Points |
    Where-Object { $_ -and $_[0] -ne '#' } |
    ForEach-Object {
      $cols = $_ -split "\s+"
      if ($cols.Count -lt 10) { return }

      $key = "$($cols[0]) $($cols[1])"
      if (-not $acc.ContainsKey($key)) {
        $acc[$key] = [ordered]@{
          ix = [int]$cols[0]
          iy = [int]$cols[1]
          x1 = [double]::Parse($cols[2], $InvariantCulture)
          x2 = [double]::Parse($cols[3], $InvariantCulture)
          sum = 0.0
          dxsum = 0.0
          dysum = 0.0
          count = 0
        }
      }
      $x1Final = [double]::Parse($cols[5], $InvariantCulture)
      $x2Final = [double]::Parse($cols[6], $InvariantCulture)
      $acc[$key].sum += [double]::Parse($cols[9], $InvariantCulture)
      $acc[$key].dxsum += $x1Final - $acc[$key].x1
      $acc[$key].dysum += $x2Final - $acc[$key].x2
      $acc[$key].count += 1
    }

  $acc.Values |
    Sort-Object ix,iy |
    ForEach-Object {
      [string]::Format(
        $InvariantCulture,
        "{0:F12} {1:F12} {2:F12} {3:F12} {4:F12} {5}",
        $_.x1,
        $_.x2,
        ($_.sum / $_.count),
        ($_.dxsum / $_.count),
        ($_.dysum / $_.count),
        $_.count
      )
    } |
    Set-Content -Encoding ASCII -LiteralPath $InitialAvg
}

[regex]::Matches($header, "(A'|B'|[ABCDE]):?=?\(([-0-9.]+),([-0-9.]+)\)") |
  ForEach-Object {
    "{0} {1} {2}" -f $_.Groups[1].Value,$_.Groups[2].Value,$_.Groups[3].Value
  } |
  Set-Content -Encoding ASCII -LiteralPath $Fixed

Write-FixedPointStability $Fixed $FixedStable $tag $headerLines
Write-Nullclines $Nullcline1 $Nullcline2 $tag $headerLines
Write-ParamLabels $tag $headerLines $Params
