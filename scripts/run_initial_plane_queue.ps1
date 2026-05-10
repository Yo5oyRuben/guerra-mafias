param(
  [int]$Jobs = 12,
  [int]$NDiv = 10,
  [int]$NReps = 5,
  [int]$MaxRuns = -1,
  [string]$Preset = 'default',
  [switch]$DryRun,
  [switch]$NoPlot,
  [switch]$SkipExisting
)

$ErrorActionPreference = 'Stop'

$Base = 'c_paper'
$ConfigPath = "$Base/config.h"
$BackupPath = "$ConfigPath.queue_backup"
$QueueStamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogDir = "$Base/out/logs"
$PresetLabel = $Preset -replace '[^A-Za-z0-9_]', '_'
$LogPath = "$LogDir/initial_plane_queue_${PresetLabel}_$QueueStamp.log"
$ManifestPath = "$LogDir/initial_plane_queue_${PresetLabel}_$QueueStamp.tsv"

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

function Write-Log([string]$Message) {
  $line = "{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
  $line | Tee-Object -FilePath $LogPath -Append
}

function Set-DefineValue([string]$Text, [string]$Name, [string]$Value) {
  $pattern = "(?m)^#define\s+$Name\s+.*$"
  $replacement = "#define $Name $Value"
  if ($Text -notmatch $pattern) {
    throw "No encuentro #define $Name en $ConfigPath"
  }
  return [regex]::Replace($Text, $pattern, $replacement)
}

function Safe-Tag([string]$Value) {
  $s = $Value.Trim()
  $s = $s -replace '\s+', ''
  $s = $s -replace '\(', ''
  $s = $s -replace '\)', ''
  $s = $s -replace '\.', 'p'
  $s = $s -replace '-', 'm'
  $s = $s -replace '\+', 'p'
  $s = $s -replace '/', 'over'
  $s = $s -replace '[^A-Za-z0-9_]', '_'
  if ($s.Length -eq 0) { return 'NA' }
  return $s
}

function Get-RunTag($Job) {
  $n1 = $Job.N1
  $n2 = $Job.N2
  if ($null -eq $n1) { $n1 = $Job.N }
  if ($null -eq $n2) { $n2 = $Job.N }
  $tagParts = @(
    "N1_$(Safe-Tag ([string]$n1))",
    "N2_$(Safe-Tag ([string]$n2))",
    "P11_$(Safe-Tag ([string]$Job.P11))",
    "P12_$(Safe-Tag ([string]$Job.P12))",
    "P22_$(Safe-Tag ([string]$Job.P22))",
    "B_$(Safe-Tag ([string]$Job.B))",
    "R_$(Safe-Tag ([string]$Job.R))",
    "E_$(Safe-Tag ([string]$Job.E))",
    "TMAX_$(Safe-Tag ([string]$Job.T_MAX))",
    "ndiv_$NDiv",
    "reps_$NReps"
  )
  return ($tagParts -join '__')
}

$JobsToRun = @()

if ($Preset -eq 'connectivityScaling') {
  foreach ($pintra in @('0.02', '0.05', '0.10', '0.20', '0.50', '0.90')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $pintra
      P12 = '0.20'
      P22 = $pintra
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '25000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'connectivityScalingFine') {
  foreach ($pintra in @('0.55', '0.60', '0.65', '0.70', '0.75', '0.80', '0.85')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $pintra
      P12 = '0.20'
      P22 = $pintra
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '25000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'connectivityScalingExtra') {
  foreach ($pintra in @('0.30', '0.40', '0.715', '0.73')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $pintra
      P12 = '0.20'
      P22 = $pintra
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '25000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'torreCriticalP12ScanT400k') {
  foreach ($p12 in @('0.05', '0.10', '0.15', '0.25', '0.30', '0.40')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = '0.73'
      P12 = $p12
      P22 = '0.73'
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'torreCriticalBScanT400k') {
  foreach ($b in @('1.05', '1.10', '1.20', '1.30')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = '0.73'
      P12 = '0.20'
      P22 = '0.73'
      B = $b
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'torreCriticalP11P12GridT400k') {
  foreach ($p12 in @('0.16', '0.20', '0.24')) {
    foreach ($pintra in @('0.65', '0.70', '0.73', '0.76', '0.80')) {
      $JobsToRun += [pscustomobject]@{
        N1 = '500'
        N2 = '500'
        P11 = $pintra
        P12 = $p12
        P22 = $pintra
        B = '1.15'
        R = '0'
        E = '-0.4'
        T_MCS = '1000'
        T_MAX = '400000'
        W = '2000'
      }
    }
  }
} elseif ($Preset -eq 'torreCriticalP11P12RefineT400k') {
  foreach ($p12 in @('0.21', '0.22', '0.23')) {
    foreach ($pintra in @('0.70', '0.73', '0.76', '0.80')) {
      $JobsToRun += [pscustomobject]@{
        N1 = '500'
        N2 = '500'
        P11 = $pintra
        P12 = $p12
        P22 = $pintra
        B = '1.15'
        R = '0'
        E = '-0.4'
        T_MCS = '1000'
        T_MAX = '400000'
        W = '2000'
      }
    }
  }
} elseif ($Preset -eq 'torreCriticalHighP11FrontierT400k') {
  foreach ($entry in @(
    [pscustomobject]@{P12='0.21'; P11s=@('0.77', '0.78', '0.79', '0.80')},
    [pscustomobject]@{P12='0.22'; P11s=@('0.79', '0.80', '0.82', '0.84')},
    [pscustomobject]@{P12='0.23'; P11s=@('0.80', '0.83', '0.86', '0.90')}
  )) {
    foreach ($pintra in $entry.P11s) {
      $JobsToRun += [pscustomobject]@{
        N1 = '500'
        N2 = '500'
        P11 = $pintra
        P12 = $entry.P12
        P22 = $pintra
        B = '1.15'
        R = '0'
        E = '-0.4'
        T_MCS = '1000'
        T_MAX = '400000'
        W = '2000'
      }
    }
  }
} elseif ($Preset -eq 'torreCriticalBoundaryRobustT400k') {
  foreach ($job in @(
    [pscustomobject]@{P12='0.21'; P11='0.80'},
    [pscustomobject]@{P12='0.22'; P11='0.80'},
    [pscustomobject]@{P12='0.22'; P11='0.82'},
    [pscustomobject]@{P12='0.23'; P11='0.86'}
  )) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $job.P11
      P12 = $job.P12
      P22 = $job.P11
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'torreCriticalFrontierFollowupT400k') {
  foreach ($job in @(
    [pscustomobject]@{P12='0.22'; P11='0.81'},
    [pscustomobject]@{P12='0.23'; P11='0.84'},
    [pscustomobject]@{P12='0.23'; P11='0.85'},
    [pscustomobject]@{P12='0.24'; P11='0.86'},
    [pscustomobject]@{P12='0.24'; P11='0.88'},
    [pscustomobject]@{P12='0.24'; P11='0.90'}
  )) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $job.P11
      P12 = $job.P12
      P22 = $job.P11
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'highNAsym') {
  $JobsToRun += @(
    [pscustomobject]@{N1='200'; N2='600'; P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='200'; N2='600'; P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='600'; N2='200'; P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='600'; N2='200'; P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'}
  )
} elseif ($Preset -eq 'highNAsymLarge') {
  $JobsToRun += @(
    [pscustomobject]@{N1='400';  N2='1200'; P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='400';  N2='1200'; P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='1200'; N2='400';  P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='1200'; N2='400';  P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='300';  N2='1500'; P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='300';  N2='1500'; P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='1500'; N2='300';  P11='0.9'; P12='0.02'; P22='0.9'; B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'},
    [pscustomobject]@{N1='1500'; N2='300';  P11='0.9'; P12='0.03'; P22='0.9'; B='1.10'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='25000'; W='2000'}
  )
} elseif ($Preset -eq 'relaxationPilot50k') {
  $JobsToRun += @(
    [pscustomobject]@{N1='500';  N2='500';  P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='50000'; W='2000'},
    [pscustomobject]@{N1='500';  N2='500';  P11='0.90'; P12='0.20'; P22='0.90'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='50000'; W='2000'},
    [pscustomobject]@{N1='400';  N2='1200'; P11='0.9';  P12='0.02'; P22='0.9';  B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='50000'; W='2000'},
    [pscustomobject]@{N1='1200'; N2='400';  P11='0.9';  P12='0.02'; P22='0.9';  B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='50000'; W='2000'}
  )
} elseif ($Preset -eq 'relaxationLadder') {
  foreach ($tmax in @('50000', '100000')) {
    $JobsToRun += @(
      [pscustomobject]@{N1='500';  N2='500';  P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX=$tmax; W='2000'},
      [pscustomobject]@{N1='500';  N2='500';  P11='0.90'; P12='0.20'; P22='0.90'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX=$tmax; W='2000'},
      [pscustomobject]@{N1='400';  N2='1200'; P11='0.9';  P12='0.02'; P22='0.9';  B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX=$tmax; W='2000'},
      [pscustomobject]@{N1='1200'; N2='400';  P11='0.9';  P12='0.02'; P22='0.9';  B='1.06'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX=$tmax; W='2000'}
    )
  }
} elseif ($Preset -eq 'relaxationP073T200k') {
  $JobsToRun += @(
    [pscustomobject]@{N1='500'; N2='500'; P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='200000'; W='2000'}
  )
} elseif ($Preset -eq 'relaxationP073T400k') {
  $JobsToRun += @(
    [pscustomobject]@{N1='500'; N2='500'; P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='400000'; W='2000'}
  )
} elseif ($Preset -eq 'relaxationCriticalPFineT400k') {
  foreach ($pintra in @('0.70', '0.715', '0.745', '0.76', '0.80')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $pintra
      P12 = '0.20'
      P22 = $pintra
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'relaxationCriticalPNarrowT400k') {
  foreach ($pintra in @('0.720', '0.725', '0.735', '0.740')) {
    $JobsToRun += [pscustomobject]@{
      N1 = '500'
      N2 = '500'
      P11 = $pintra
      P12 = '0.20'
      P22 = $pintra
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'relaxationCriticalNScalingT400k') {
  foreach ($n in @('250', '750', '1000')) {
    $JobsToRun += [pscustomobject]@{
      N1 = $n
      N2 = $n
      P11 = '0.73'
      P12 = '0.20'
      P22 = '0.73'
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'relaxationCriticalNScalingRemainingT400k') {
  foreach ($n in @('750', '1000')) {
    $JobsToRun += [pscustomobject]@{
      N1 = $n
      N2 = $n
      P11 = '0.73'
      P12 = '0.20'
      P22 = '0.73'
      B = '1.15'
      R = '0'
      E = '-0.4'
      T_MCS = '1000'
      T_MAX = '400000'
      W = '2000'
    }
  }
} elseif ($Preset -eq 'relaxationCriticalAsymT400k') {
  $JobsToRun += @(
    [pscustomobject]@{N1='400';  N2='1200'; P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='400000'; W='2000'},
    [pscustomobject]@{N1='1200'; N2='400';  P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='400000'; W='2000'}
  )
} elseif ($Preset -eq 'relaxationCriticalStatsT400k') {
  $JobsToRun += @(
    [pscustomobject]@{N1='500'; N2='500'; P11='0.73'; P12='0.20'; P22='0.73'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='400000'; W='2000'}
  )
} elseif ($Preset -eq 'lowNAsym') {
  $JobsToRun += @(
    [pscustomobject]@{N1='20';  N2='20';  P11='0.9'; P12='0.2'; P22='0.9'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='40';  N2='40';  P11='0.9'; P12='0.2'; P22='0.9'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='80';  N2='80';  P11='0.9'; P12='0.2'; P22='0.9'; B='1.15'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},

    [pscustomobject]@{N1='30';  N2='40';  P11='0.9'; P12='0.1'; P22='0.9'; B='1.08'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='60';  N2='80';  P11='0.9'; P12='0.1'; P22='0.9'; B='1.08'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='120'; N2='160'; P11='0.9'; P12='0.1'; P22='0.9'; B='1.08'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},

    [pscustomobject]@{N1='30';  N2='40';  P11='0.9'; P12='0.2'; P22='0.9'; B='1.20'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='60';  N2='80';  P11='0.9'; P12='0.2'; P22='0.9'; B='1.20'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='120'; N2='160'; P11='0.9'; P12='0.2'; P22='0.9'; B='1.20'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},

    [pscustomobject]@{N1='25';  N2='50';  P11='0.9'; P12='0.1'; P22='0.9'; B='1.12'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='50';  N2='100'; P11='0.9'; P12='0.1'; P22='0.9'; B='1.12'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'},
    [pscustomobject]@{N1='100'; N2='200'; P11='0.9'; P12='0.1'; P22='0.9'; B='1.12'; R='0'; E='-0.4'; T_MCS='1000'; T_MAX='30000'; W='2000'}
  )
} elseif ($Preset -eq 'default') {
  foreach ($n in @('100', '200', '400')) {
    foreach ($p12 in @('0.1', '0.3')) {
      foreach ($b in @('1.174', '1.3')) {
        $JobsToRun += [pscustomobject]@{
          N1 = $n
          N2 = $n
          P11 = '0.9'
          P12 = $p12
          P22 = '0.9'
          B = $b
          R = '0'
          E = '-0.4'
          T_MCS = '1000'
          T_MAX = '30000'
          W = '2000'
        }
      }
    }
  }
} else {
  throw "Preset desconocido: $Preset"
}

if ($MaxRuns -ge 0 -and $MaxRuns -lt $JobsToRun.Count) {
  $JobsToRun = @($JobsToRun | Select-Object -First $MaxRuns)
}

"index`tN1`tN2`tP11`tP12`tP22`tB`tR`tE`tndiv`treps`toutput`tplot" |
  Set-Content -Encoding ASCII -LiteralPath $ManifestPath

for ($i = 0; $i -lt $JobsToRun.Count; $i++) {
  $job = $JobsToRun[$i]
  $n1 = $job.N1
  $n2 = $job.N2
  if ($null -eq $n1) { $n1 = $job.N }
  if ($null -eq $n2) { $n2 = $job.N }
  $tag = Get-RunTag $job
  $output = "$Base/out/raw/initial_plane/initial_plane__$tag.txt"
  $plot = "$Base/out/plots/initial_plane/initial_plane__$tag.png"
  "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}`t{12}" -f `
    ($i + 1), $n1, $n2, $job.P11, $job.P12, $job.P22, $job.B, $job.R, $job.E, $NDiv, $NReps, $output, $plot |
    Add-Content -Encoding ASCII -LiteralPath $ManifestPath
}

Write-Log "Cola initial_plane preparada: preset=$Preset simulaciones=$($JobsToRun.Count). Jobs=$Jobs NDiv=$NDiv NReps=$NReps"
Write-Log "Manifest: $ManifestPath"

if ($DryRun) {
  Get-Content -LiteralPath $ManifestPath | Tee-Object -FilePath $LogPath -Append
  Write-Log "Dry-run terminado. No se ha lanzado ninguna simulacion."
  exit 0
}

$OriginalConfig = Get-Content -LiteralPath $ConfigPath -Raw
$OriginalConfig | Set-Content -Encoding ASCII -LiteralPath $BackupPath

try {
  for ($i = 0; $i -lt $JobsToRun.Count; $i++) {
    $job = $JobsToRun[$i]
    $n1 = $job.N1
    $n2 = $job.N2
    if ($null -eq $n1) { $n1 = $job.N }
    if ($null -eq $n2) { $n2 = $job.N }
    $tag = Get-RunTag $job
    $output = "$Base/out/raw/initial_plane/initial_plane__$tag.txt"
    $plot = "$Base/out/plots/initial_plane/initial_plane__$tag.png"

    if ($SkipExisting -and (Test-Path -LiteralPath $output) -and ((Get-Item -LiteralPath $output).Length -gt 0)) {
      Write-Log "SKIP $($i + 1)/$($JobsToRun.Count): $tag output existente=$output"
      continue
    }

    $sw = [Diagnostics.Stopwatch]::StartNew()

    Write-Log "START $($i + 1)/$($JobsToRun.Count): $tag"

    $cfg = $OriginalConfig
    $cfg = Set-DefineValue $cfg 'N1' ([string]$n1)
    $cfg = Set-DefineValue $cfg 'N2' ([string]$n2)
    $cfg = Set-DefineValue $cfg 'T_MCS' ([string]$job.T_MCS)
    $cfg = Set-DefineValue $cfg 'T_MAX' ([string]$job.T_MAX)
    $cfg = Set-DefineValue $cfg 'W' ([string]$job.W)
    $cfg = Set-DefineValue $cfg 'P11' ([string]$job.P11)
    $cfg = Set-DefineValue $cfg 'P12' ([string]$job.P12)
    $cfg = Set-DefineValue $cfg 'P22' ([string]$job.P22)
    $cfg = Set-DefineValue $cfg 'R' ([string]$job.R)
    $cfg = Set-DefineValue $cfg 'E' ([string]$job.E)
    $cfg = Set-DefineValue $cfg 'B' ([string]$job.B)
    $cfg = Set-DefineValue $cfg 'N_INI_NDIV' ([string]$NDiv)
    $cfg = Set-DefineValue $cfg 'N_INI_COND' ([string]$NReps)
    $cfg | Set-Content -Encoding ASCII -LiteralPath $ConfigPath

    & powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run_initial_plane_parallel.ps1 `
      -Jobs $Jobs -NDiv $NDiv -NReps $NReps -Output $output *>&1 |
      Tee-Object -FilePath $LogPath -Append

    if ($LASTEXITCODE -ne 0) {
      throw "Fallo la simulacion $tag con codigo $LASTEXITCODE"
    }

    if (-not $NoPlot) {
      $gnuplot = Get-Command gnuplot -ErrorAction SilentlyContinue
      if ($gnuplot) {
        & gnuplot -e "infile='$output'; outfile='$plot'" c_paper/out/gp/plot_initial_plane.gp *>&1 |
          Tee-Object -FilePath $LogPath -Append

        if ($LASTEXITCODE -ne 0) {
          throw "Fallo gnuplot para $tag con codigo $LASTEXITCODE"
        }
      } else {
        Write-Log "WARN: gnuplot no esta en PATH; salto la grafica de $tag"
      }
    }

    $sw.Stop()
    Write-Log "END $($i + 1)/$($JobsToRun.Count): $tag elapsed=$($sw.Elapsed)"
  }

  Write-Log "Cola terminada correctamente."
} finally {
  $OriginalConfig | Set-Content -Encoding ASCII -LiteralPath $ConfigPath
  Write-Log "config.h restaurado desde el estado inicial de la cola."
}
