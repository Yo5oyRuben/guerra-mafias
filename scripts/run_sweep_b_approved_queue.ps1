param(
  [switch]$Controller,
  [string]$OutRoot = '',
  [int]$MaxParallel = 3,
  [int]$RepsPaper = 200,
  [int]$RepsStrong = 150,
  [int]$NDIV = 401,
  [int]$T_MCS = 1000,
  [int]$T_MAX = 50000,
  [int]$W = 2000
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo
$InvariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

if ($OutRoot -eq '') {
  $stamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
  $OutRoot = "c_paper/out/experiments/sweep_b_$stamp"
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

if (-not $Controller) {
  New-Item -ItemType Directory -Force -Path $OutRoot,$LogDir | Out-Null
  $scriptPath = Join-Path $PSScriptRoot 'run_sweep_b_approved_queue.ps1'
  $argsList = ('-NoProfile -ExecutionPolicy Bypass -Command "& ''{0}'' -Controller -OutRoot ''{1}'' ' +
               '-MaxParallel {2} -RepsPaper {3} -RepsStrong {4} -NDIV {5} -T_MCS {6} -T_MAX {7} -W {8}"') -f `
              $scriptPath,$OutRoot,$MaxParallel,$RepsPaper,$RepsStrong,$NDIV,$T_MCS,$T_MAX,$W
  $p = Start-Process powershell.exe -ArgumentList $argsList -WorkingDirectory $Repo -WindowStyle Hidden -PassThru `
       -RedirectStandardOutput $ControllerLog -RedirectStandardError (Join-Path $LogDir 'controller.err.log')
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
  param(
    [string]$Exe,
    [int]$N1,
    [int]$N2
  )

  $cc = Get-Compiler
  $base = 'c_paper'
  $flags = @(
    '-O3','-std=c90','-pedantic','-Wall','-Wextra',
    "-DN1=$N1",
    "-DN2=$N2",
    "-DNDIV=$NDIV",
    "-DT_MCS=$T_MCS",
    "-DT_MAX=$T_MAX",
    "-DW=$W",
    '-DP11=(6.0/(N1-1.0))',
    '-DP22=(6.0/(N2-1.0))',
    '-DR=0',
    '-DE=-0.4',
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
    [string]$Family,
    [string]$Exe,
    [double]$P12,
    [double]$X01,
    [double]$X02,
    [double]$BMin,
    [double]$BMax,
    [int]$Reps,
    [uint32]$Seed
  )

  $tagP = ([string]::Format($InvariantCulture, '{0:g}', $P12)).Replace('.', 'p')
  $out = Join-Path $RawDir ("{0}_p12_{1}.tsv" -f $Family,$tagP)
  $log = Join-Path $LogDir ("{0}_p12_{1}.log" -f $Family,$tagP)
  [void]$Rows.Add([pscustomobject]@{
    family = $Family
    exe = $Exe
    p12 = $P12
    x01 = $X01
    x02 = $X02
    bmin = $BMin
    bmax = $BMax
    reps = $Reps
    seed = $Seed
    output = $out
    log = $log
  })
}

function Format-Double {
  param([double]$Value)
  return [string]::Format($InvariantCulture, '{0:g}', $Value)
}

function Quote-Arg {
  param([string]$Value)
  return '"' + ($Value -replace '"','\"') + '"'
}

"time`tmessage" | Set-Content -Path $ControllerLog
("{0}`tstarting sweep queue; independence=graph_per_b_rep" -f (Get-Date -Format s)) | Add-Content -Path $ControllerLog

$exeFig3 = Join-Path $BuildDir 'sweep_stats_N1000_N1000.exe'
$exeFig4 = Join-Path $BuildDir 'sweep_stats_N1000_N100.exe'

Build-SweepStats -Exe $exeFig3 -N1 1000 -N2 1000
Build-SweepStats -Exe $exeFig4 -N1 1000 -N2 100

$rows = [System.Collections.ArrayList]::new()
$paperP = @(0.0,0.001,0.002,0.005,0.01,0.02,0.04)
$strongP = @(0.04,0.06,0.08,0.10,0.15)

$idx = 0
foreach ($p12 in $paperP) {
  Add-JobRow -Rows $rows -Family 'fig3_paper' -Exe $exeFig3 -P12 $p12 `
    -X01 0.5 -X02 0.5 -BMin 1.0 -BMax 3.0 -Reps $RepsPaper -Seed ([uint32](120000 + $idx))
  $idx++
}
foreach ($p12 in $paperP) {
  Add-JobRow -Rows $rows -Family 'fig4_paper' -Exe $exeFig4 -P12 $p12 `
    -X01 0.5 -X02 0.0 -BMin 1.0 -BMax 4.0 -Reps $RepsPaper -Seed ([uint32](220000 + $idx))
  $idx++
}
foreach ($p12 in $strongP) {
  Add-JobRow -Rows $rows -Family 'fig4_strong_coupling' -Exe $exeFig4 -P12 $p12 `
    -X01 0.5 -X02 0.0 -BMin 1.0 -BMax 5.0 -Reps $RepsStrong -Seed ([uint32](320000 + $idx))
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
