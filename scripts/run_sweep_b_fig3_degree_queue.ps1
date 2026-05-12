param(
  [switch]$Controller,
  [string]$OutRoot = '',
  [int]$MaxParallel = 3,
  [int]$Reps = 200,
  [int]$NDIV = 401,
  [int]$T_MCS = 1000,
  [int]$T_MAX = 50000,
  [int]$W = 2000,
  [double]$DegreeAlpha = 1.0,
  [double]$DegreeFactorMin = 0.3333333333333333,
  [double]$DegreeFactorMax = 3.0,
  [string]$P12List = '0,0.001,0.002,0.005,0.01,0.02,0.04'
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Format-Double {
  param([double]$Value)
  return [string]::Format($InvariantCulture, '{0:g}', $Value)
}

function Quote-Arg {
  param([string]$Value)
  return '"' + ($Value -replace '"','\"') + '"'
}

function Safe-Tag {
  param([double]$Value)
  return ([string]::Format($InvariantCulture, '{0:g}', $Value)).Replace('.', 'p').Replace('-', 'm')
}

if ($OutRoot -eq '') {
  $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $alphaTag = Safe-Tag $DegreeAlpha
  $OutRoot = "c_paper/out/experiments/sweep_b_fig3_degree_alpha_${alphaTag}_$stamp"
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
  $scriptPath = Join-Path $PSScriptRoot 'run_sweep_b_fig3_degree_queue.ps1'
  $argsList = ('-NoProfile -ExecutionPolicy Bypass -Command "& ''{0}'' -Controller -OutRoot ''{1}'' ' +
               '-MaxParallel {2} -Reps {3} -NDIV {4} -T_MCS {5} -T_MAX {6} -W {7} ' +
               '-DegreeAlpha {8} -DegreeFactorMin {9} -DegreeFactorMax {10} -P12List ''{11}''"') -f `
              $scriptPath,$OutRoot,$MaxParallel,$Reps,$NDIV,$T_MCS,$T_MAX,$W,
              (Format-Double $DegreeAlpha),(Format-Double $DegreeFactorMin),(Format-Double $DegreeFactorMax),$P12List
  $p = Start-Process powershell.exe -ArgumentList $argsList -WorkingDirectory $Repo -WindowStyle Hidden -PassThru `
       -RedirectStandardOutput $LauncherLog -RedirectStandardError (Join-Path $LogDir 'controller.err.log')
  Write-Host "Controlador lanzado: PID $($p.Id)"
  Write-Host "OutRoot: $OutRoot"
  Write-Host "Manifest: $Manifest"
  Write-Host "Log controlador: $ControllerLog"
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

function Build-SweepStats {
  param([string]$Exe)

  $cc = Get-Compiler
  $base = 'c_paper'
  $flags = @(
    '-O3','-std=c90','-pedantic','-Wall','-Wextra',
    '-DN1=1000',
    '-DN2=1000',
    "-DNDIV=$NDIV",
    "-DT_MCS=$T_MCS",
    "-DT_MAX=$T_MAX",
    "-DW=$W",
    '-DP11=(6.0/(N1-1.0))',
    '-DP22=(6.0/(N2-1.0))',
    '-DR=0',
    '-DE=-0.4',
    '-DUPDATE_RULE=2',
    "-DDEGREE_ALPHA=$(Format-Double $DegreeAlpha)",
    "-DDEGREE_FACTOR_MIN=$(Format-Double $DegreeFactorMin)",
    "-DDEGREE_FACTOR_MAX=$(Format-Double $DegreeFactorMax)",
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
    [string]$Exe,
    [double]$P12,
    [uint32]$Seed
  )

  $tagP = Safe-Tag $P12
  $alphaTag = Safe-Tag $DegreeAlpha
  $out = Join-Path $RawDir ("fig3_degree_alpha_{0}_p12_{1}.tsv" -f $alphaTag,$tagP)
  $log = Join-Path $LogDir ("fig3_degree_alpha_{0}_p12_{1}.log" -f $alphaTag,$tagP)
  [void]$Rows.Add([pscustomobject]@{
    family = 'fig3_degree'
    exe = $Exe
    p12 = $P12
    x01 = 0.5
    x02 = 0.5
    bmin = 1.0
    bmax = 3.0
    reps = $Reps
    seed = $Seed
    output = $out
    log = $log
  })
}

"time`tmessage" | Set-Content -Path $ControllerLog
("{0}`tstarting fig3 degree sweep; alpha={1}; clamp=[{2},{3}]; independence=graph_per_b_rep" -f
  (Get-Date -Format s),(Format-Double $DegreeAlpha),(Format-Double $DegreeFactorMin),(Format-Double $DegreeFactorMax)) |
  Add-Content -Path $ControllerLog

$exeFig3 = Join-Path $BuildDir 'sweep_stats_fig3_degree_N1000_N1000.exe'
Build-SweepStats -Exe $exeFig3

$rows = [System.Collections.ArrayList]::new()
$paperP = @($P12List.Split(',') | ForEach-Object { [double]::Parse($_.Trim(), $InvariantCulture) })
$idx = 0
foreach ($p12 in $paperP) {
  Add-JobRow -Rows $rows -Exe $exeFig3 -P12 $p12 -Seed ([uint32](830000 + $idx))
  $idx++
}

"index?family?exe?p12?x01?x02?bmin?bmax?reps?seed?output?log".Replace('?',"`t") |
  Set-Content -Path $Manifest
for ($i = 0; $i -lt $rows.Count; $i++) {
  $r = $rows[$i]
  ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}`t{7}`t{8}`t{9}`t{10}`t{11}" -f
    ($i + 1), $r.family, $r.exe, (Format-Double $r.p12), (Format-Double $r.x01),
    (Format-Double $r.x02), (Format-Double $r.bmin), (Format-Double $r.bmax),
    $r.reps, $r.seed, $r.output, $r.log) | Add-Content -Path $Manifest
}

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
    ("{0}`tstarted {1}/{2} {3} p12={4} pid={5}" -f
      (Get-Date -Format s), ($next + 1), $rows.Count, $r.family,
      (Format-Double $r.p12), $proc.Id) |
      Add-Content -Path $ControllerLog
    $next++
  }

  Start-Sleep -Seconds 20
  $still = @()
  foreach ($item in $running) {
    $item.process.Refresh()
    if ($item.process.HasExited) {
      ("{0}`tfinished {1}/{2} {3} p12={4} exit={5}" -f
        (Get-Date -Format s), $item.index, $rows.Count, $item.row.family,
        (Format-Double $item.row.p12), $item.process.ExitCode) | Add-Content -Path $ControllerLog
      if ($null -ne $item.process.ExitCode -and $item.process.ExitCode -ne 0) {
        ("{0}`terror in {1}" -f (Get-Date -Format s), $item.row.log) |
          Add-Content -Path $ControllerLog
      }
    } else {
      $still += $item
    }
  }
  $running = $still
}

("{0}`tqueue completed" -f (Get-Date -Format s)) | Add-Content -Path $ControllerLog
