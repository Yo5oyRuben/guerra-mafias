param(
  [switch]$Controller,
  [string]$OutRoot = '',
  [int]$MaxParallel = 4,
  [int]$Reps = 30,
  [int]$NDIV = 121,
  [int]$T_MCS = 1000,
  [int]$T_MAX = 25000,
  [int]$W = 2000,
  [string]$PaperP12List = '0,0.001,0.002,0.005,0.01,0.02,0.04',
  [string]$AlphaList = '1,2,5,10',
  [double]$AlphaSweepP12 = 0.1,
  [double]$DegreeFactorMin = 0.3333333333333333,
  [double]$DegreeFactorMax = 3.0
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Double {
  param([double]$Value)
  return [string]::Format($InvariantCulture, '{0:g}', $Value)
}

function Tag-Double {
  param([double]$Value)
  return (Format-Double $Value).Replace('.', 'p')
}

function Parse-DoubleList {
  param([string]$Text)
  return @($Text.Split(',') | ForEach-Object {
    [double]::Parse($_.Trim(), $InvariantCulture)
  })
}

if ($OutRoot -eq '') {
  $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $OutRoot = "c_paper/out/experiments/fig4_degree_linear_alpha_sweep_$stamp"
}

if (-not [System.IO.Path]::IsPathRooted($OutRoot)) {
  $OutRoot = Join-Path $Repo $OutRoot
}
$OutRoot = [System.IO.Path]::GetFullPath($OutRoot)
$OutRoot = $OutRoot -replace '\\','/'
$BuildDir = Join-Path $OutRoot 'build'
$RawDir = Join-Path $OutRoot 'raw'
$LogDir = Join-Path $OutRoot 'logs'
$Manifest = Join-Path $OutRoot 'manifest.tsv'
$ControllerLog = Join-Path $OutRoot 'controller.log'
$LauncherLog = Join-Path $OutRoot 'launcher.log'

if (-not $Controller) {
  New-Item -ItemType Directory -Force -Path $OutRoot,$LogDir | Out-Null
  $scriptPath = Join-Path $PSScriptRoot 'run_sweep_b_fig4_degree_queue.ps1'
  $argsList = ('-NoProfile -ExecutionPolicy Bypass -Command "& ''{0}'' -Controller -OutRoot ''{1}'' ' +
               '-MaxParallel {2} -Reps {3} -NDIV {4} -T_MCS {5} -T_MAX {6} -W {7} ' +
               '-PaperP12List ''{8}'' -AlphaList ''{9}'' -AlphaSweepP12 {10} -DegreeFactorMin {11} -DegreeFactorMax {12}"') -f `
              $scriptPath,$OutRoot,$MaxParallel,$Reps,$NDIV,$T_MCS,$T_MAX,$W,
              $PaperP12List,$AlphaList,(Format-Double $AlphaSweepP12),
              (Format-Double $DegreeFactorMin),(Format-Double $DegreeFactorMax)
  $p = Start-Process powershell.exe -ArgumentList $argsList -WorkingDirectory $Repo -WindowStyle Hidden -PassThru `
       -RedirectStandardOutput $LauncherLog -RedirectStandardError (Join-Path $LogDir 'controller.err.log')
  Write-Host "Controlador lanzado: PID $($p.Id)"
  Write-Host "OutRoot: $OutRoot"
  Write-Host "Manifest: $Manifest"
  Write-Host "Log controlador: $ControllerLog"
  Write-Host "Log lanzador: $LauncherLog"
  exit 0
}

New-Item -ItemType Directory -Force -Path $OutRoot,$BuildDir,$RawDir,$LogDir | Out-Null

function Get-Compiler {
  $gcc = Get-Command gcc -ErrorAction SilentlyContinue
  if ($gcc) { return $gcc.Source }
  $clang = Get-Command clang -ErrorAction SilentlyContinue
  if ($clang) { return $clang.Source }
  throw 'No se encontro gcc ni clang en PATH.'
}

function Quote-Arg {
  param([string]$Value)
  return '"' + ($Value -replace '"','\"') + '"'
}

function Build-SweepStats {
  param(
    [string]$Exe,
    [double]$Alpha
  )

  $cc = Get-Compiler
  $base = 'c_paper'
  $flags = @(
    '-O3','-std=c90','-pedantic','-Wall','-Wextra',
    '-DN1=1000',
    '-DN2=100',
    "-DNDIV=$NDIV",
    "-DT_MCS=$T_MCS",
    "-DT_MAX=$T_MAX",
    "-DW=$W",
    '-DP11=(6.0/(N1-1.0))',
    '-DP22=(6.0/(N2-1.0))',
    '-DR=0',
    '-DE=-0.4',
    '-DUPDATE_RULE=2',
    "-DDEGREE_ALPHA=$([string]::Format($InvariantCulture, '{0:g}', $Alpha))",
    "-DDEGREE_FACTOR_MIN=$([string]::Format($InvariantCulture, '{0:g}', $DegreeFactorMin))",
    "-DDEGREE_FACTOR_MAX=$([string]::Format($InvariantCulture, '{0:g}', $DegreeFactorMax))",
    '-I', $base,
    '-I', "$base/core",
    '-I', "$base/apps",
    '-I', "$base/apps/sweep_b"
  )
  $src = @(
    "$base/core/rng.c",
    "$base/core/graph.c",
    "$base/core/state.c",
    "$base/core/payoff.c",
    "$base/core/dynamics.c",
    "$base/core/sim.c",
    "$base/core/utils.c",
    "$base/core/io.c",
    "$base/apps/sweep_b/run_sweep_b_stats.c"
  )
  & $cc @flags @src '-lm' '-o' $Exe
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo compilando $Exe"
  }
}

function Add-JobRow {
  param(
    [System.Collections.ArrayList]$Rows,
    [hashtable]$ExeByAlpha,
    [string]$Family,
    [double]$Alpha,
    [double]$P12,
    [uint32]$Seed
  )

  $alphaTag = Tag-Double $Alpha
  $pTag = Tag-Double $P12
  $out = Join-Path $RawDir ("fig4_degree_{0}_alpha_{1}_p12_{2}.tsv" -f $Family,$alphaTag,$pTag)
  $log = Join-Path $LogDir ("fig4_degree_{0}_alpha_{1}_p12_{2}.log" -f $Family,$alphaTag,$pTag)
  [void]$Rows.Add([pscustomobject]@{
    family = $Family
    exe = $ExeByAlpha[(Format-Double $Alpha)]
    alpha = $Alpha
    p12 = $P12
    x01 = 0.5
    x02 = 0.0
    bmin = 1.0
    bmax = 4.0
    reps = $Reps
    seed = $Seed
    output = $out
    log = $log
  })
}

"time`tmessage" | Set-Content -Encoding ASCII -Path $ControllerLog
("{0}`tstarting fig4 degree sweep; reps={1}; ndiv={2}; clamp=[{3},{4}]" -f
  (Get-Date -Format s),$Reps,$NDIV,(Format-Double $DegreeFactorMin),(Format-Double $DegreeFactorMax)) |
  Add-Content -Encoding ASCII -Path $ControllerLog

$paperP12 = Parse-DoubleList $PaperP12List
$alphas = Parse-DoubleList $AlphaList
$allAlphas = @($alphas + 1.0 | Sort-Object -Unique)

$exeByAlpha = @{}
foreach ($alpha in $allAlphas) {
  $tag = Tag-Double $alpha
  $exe = Join-Path $BuildDir ("sweep_stats_fig4_degree_alpha_{0}_N1000_N100.exe" -f $tag)
  Build-SweepStats -Exe $exe -Alpha $alpha
  $exeByAlpha[(Format-Double $alpha)] = $exe
}

$rows = [System.Collections.ArrayList]::new()
$idx = 0
foreach ($p12 in $paperP12) {
  Add-JobRow -Rows $rows -ExeByAlpha $exeByAlpha -Family 'paper_p' -Alpha 1.0 -P12 $p12 -Seed ([uint32](810000 + $idx))
  $idx++
}

$idx = 0
foreach ($alpha in $alphas) {
  Add-JobRow -Rows $rows -ExeByAlpha $exeByAlpha -Family 'alpha_sweep_p0p1' -Alpha $alpha -P12 $AlphaSweepP12 -Seed ([uint32](820000 + $idx))
  $idx++
}

"index?family?exe?alpha?p12?x01?x02?bmin?bmax?reps?seed?output?log".Replace('?',"`t") |
  Set-Content -Encoding ASCII -Path $Manifest
for ($i = 0; $i -lt $rows.Count; $i++) {
  $r = $rows[$i]
  ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}`t{12}" -f
    ($i + 1), $r.family, $r.exe, (Format-Double $r.alpha), (Format-Double $r.p12),
    (Format-Double $r.x01), (Format-Double $r.x02), (Format-Double $r.bmin),
    (Format-Double $r.bmax), $r.reps, $r.seed, $r.output, $r.log) |
    Add-Content -Encoding ASCII -Path $Manifest
}

@"
# Fig. 4 degree-linear production-ish run

Two batches:
- Paper p12 values with alpha=1.
- Fixed p12=$(Format-Double $AlphaSweepP12), alpha=$(($alphas | ForEach-Object { Format-Double $_ }) -join ', ').

Parameters:
- UPDATE_RULE=2
- DEGREE_FACTOR_MIN=$(Format-Double $DegreeFactorMin)
- DEGREE_FACTOR_MAX=$(Format-Double $DegreeFactorMax)
- N1=1000, N2=100
- P11=6/(N1-1), P22=6/(N2-1)
- b in [1,4], NDIV=$NDIV
- reps=$Reps
- T_MAX=$T_MAX
- x0=(0.5,0)
- independence=graph_per_b_rep
"@ | Set-Content -Encoding ASCII -LiteralPath (Join-Path $OutRoot 'notes.md')

$running = @()
$next = 0
while ($next -lt $rows.Count -or $running.Count -gt 0) {
  while ($next -lt $rows.Count -and $running.Count -lt $MaxParallel) {
    $r = $rows[$next]
    $args = @(
      $r.output,
      (Format-Double $r.p12),
      (Format-Double $r.x01),
      (Format-Double $r.x02),
      (Format-Double $r.bmin),
      (Format-Double $r.bmax),
      "$($r.reps)",
      "$($r.seed)"
    )
    $argLine = ($args | ForEach-Object { Quote-Arg ([string]$_) }) -join ' '
    $proc = Start-Process $r.exe -ArgumentList $argLine -WindowStyle Hidden -PassThru `
      -RedirectStandardOutput $r.log -RedirectStandardError ($r.log + '.err')
    $running += [pscustomobject]@{ process = $proc; row = $r; index = ($next + 1) }
    ("{0}`tstarted {1}/{2} {3} alpha={4} p12={5} pid={6}" -f
      (Get-Date -Format s), ($next + 1), $rows.Count, $r.family,
      (Format-Double $r.alpha), (Format-Double $r.p12), $proc.Id) |
      Add-Content -Encoding ASCII -Path $ControllerLog
    $next++
  }

  Start-Sleep -Seconds 20
  $still = @()
  foreach ($item in $running) {
    $item.process.Refresh()
    if ($item.process.HasExited) {
      ("{0}`tfinished {1}/{2} {3} alpha={4} p12={5} exit={6}" -f
        (Get-Date -Format s), $item.index, $rows.Count, $item.row.family,
        (Format-Double $item.row.alpha), (Format-Double $item.row.p12), $item.process.ExitCode) |
        Add-Content -Encoding ASCII -Path $ControllerLog
      if ($null -ne $item.process.ExitCode -and $item.process.ExitCode -ne 0) {
        ("{0}`terror in {1}" -f (Get-Date -Format s), $item.row.log) |
          Add-Content -Encoding ASCII -Path $ControllerLog
      }
    } else {
      $still += $item
    }
  }
  $running = $still
}

("{0}`tqueue completed" -f (Get-Date -Format s)) | Add-Content -Encoding ASCII -Path $ControllerLog
