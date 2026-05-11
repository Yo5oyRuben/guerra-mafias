param(
  [int]$MaxParallel = 3,
  [int]$Reps = 30,
  [int]$NDIV = 151,
  [int]$T_MCS = 1000,
  [int]$T_MAX = 50000,
  [int]$W = 2000
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

$OutRoot = Join-Path $Repo 'c_paper/out/experiments/01_paper_baselines'
$BuildDir = Join-Path $OutRoot 'build'
$RawDir = Join-Path $OutRoot 'raw'
$LogDir = Join-Path $OutRoot 'logs'
$Manifest = Join-Path $OutRoot 'fig3_strong_addition_manifest.tsv'
$ControllerLog = Join-Path $LogDir 'fig3_strong_addition_controller.log'

New-Item -ItemType Directory -Force -Path $BuildDir,$RawDir,$LogDir | Out-Null

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

$cc = Get-Compiler
$exe = Join-Path $BuildDir 'sweep_stats_fig3_N1000_N1000.exe'
$base = 'c_paper'
$flags = @(
  '-O3','-std=c90','-pedantic','-Wall','-Wextra',
  '-DN1=1000','-DN2=1000',
  "-DNDIV=$NDIV",
  "-DT_MCS=$T_MCS",
  "-DT_MAX=$T_MAX",
  "-DW=$W",
  '-DUPDATE_RULE=0',
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

& $cc @flags @src '-lm' '-o' $exe
if ($LASTEXITCODE -ne 0) { throw "Fallo compilando $exe" }

$jobs = @(
  [pscustomobject]@{ p12 = '0.06'; tag = '0p06'; seed = '120007' },
  [pscustomobject]@{ p12 = '0.08'; tag = '0p08'; seed = '120008' },
  [pscustomobject]@{ p12 = '0.10'; tag = '0p1'; seed = '120009' }
)

"time`tmessage" | Set-Content -Encoding ASCII -Path $ControllerLog
"p12`tseed`tpid`toutfile`tstdout`tstderr`tstarted" | Set-Content -Encoding ASCII -Path $Manifest

$running = @()
$next = 0
while ($next -lt $jobs.Count -or $running.Count -gt 0) {
  while ($next -lt $jobs.Count -and $running.Count -lt $MaxParallel) {
    $j = $jobs[$next]
    $out = Join-Path $RawDir ("fig3_paper_p12_{0}.tsv" -f $j.tag)
    $stdout = Join-Path $LogDir ("fig3_paper_p12_{0}.log" -f $j.tag)
    $stderr = Join-Path $LogDir ("fig3_paper_p12_{0}.err" -f $j.tag)
    $args = @($out, $j.p12, '0.5', '0.5', '1', '3', "$Reps", $j.seed)
    $argLine = ($args | ForEach-Object { Quote-Arg ([string]$_) }) -join ' '
    $proc = Start-Process $exe -ArgumentList $argLine -WindowStyle Hidden -PassThru `
      -RedirectStandardOutput $stdout -RedirectStandardError $stderr

    ("{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f
      $j.p12, $j.seed, $proc.Id, $out, $stdout, $stderr, (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) |
      Add-Content -Encoding ASCII -Path $Manifest
    ("{0}`tstarted p12={1} pid={2}" -f (Get-Date -Format s), $j.p12, $proc.Id) |
      Add-Content -Encoding ASCII -Path $ControllerLog

    $running += [pscustomobject]@{ process = $proc; job = $j }
    $next++
  }

  Start-Sleep -Seconds 20
  $still = @()
  foreach ($item in $running) {
    $item.process.Refresh()
    if ($item.process.HasExited) {
      ("{0}`tfinished p12={1} exit={2}" -f
        (Get-Date -Format s), $item.job.p12, $item.process.ExitCode) |
        Add-Content -Encoding ASCII -Path $ControllerLog
      if ($item.process.ExitCode -ne 0) {
        throw "Fallo p12=$($item.job.p12), exit=$($item.process.ExitCode)"
      }
    } else {
      $still += $item
    }
  }
  $running = $still
}

("{0}`tall done" -f (Get-Date -Format s)) | Add-Content -Encoding ASCII -Path $ControllerLog
