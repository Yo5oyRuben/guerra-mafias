param(
  [int]$ChunkJobs = 6,
  [int]$NDiv = 10,
  [int]$NReps = 5,
  [switch]$SkipExisting
)

$ErrorActionPreference = 'Stop'
$Repo = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $Repo

$Base = 'c_paper'
$Experiment = "$Base/out/experiments/02_thermodynamic_limit_high_connectivity/finite_size_scaling/symmetric_N_scaling"
$RawDir = Join-Path $Experiment 'raw'
$PartsRoot = Join-Path $Experiment 'parts'
$BuildDir = Join-Path $Experiment 'build_extra'
$LogDir = Join-Path $Experiment 'logs'
$Manifest = Join-Path $Experiment 'manifest_extra_N_scaling.tsv'
$ControllerLog = Join-Path $LogDir 'extra_N_scaling_controller.log'

New-Item -ItemType Directory -Force -Path $RawDir,$PartsRoot,$BuildDir,$LogDir | Out-Null

function Get-Compiler {
  $gcc = Get-Command gcc -ErrorAction SilentlyContinue
  if ($gcc) { return $gcc.Source }
  $clang = Get-Command clang -ErrorAction SilentlyContinue
  if ($clang) { return $clang.Source }
  throw 'No se encontro gcc ni clang en PATH.'
}

function Safe-Tag([string]$Value) {
  $s = $Value.Trim()
  $s = $s -replace '\s+', ''
  $s = $s -replace '\.', 'p'
  $s = $s -replace '-', 'm'
  $s = $s -replace '\+', 'p'
  $s = $s -replace '/', 'over'
  $s = $s -replace '[^A-Za-z0-9_]', '_'
  if ($s.Length -eq 0) { return 'NA' }
  return $s
}

function Get-RunTag($job) {
  return @(
    "N1_$(Safe-Tag $job.N)",
    "N2_$(Safe-Tag $job.N)",
    "P11_0p9",
    "P12_$(Safe-Tag $job.P12)",
    "P22_0p9",
    "B_$(Safe-Tag $job.B)",
    "R_0",
    "E_m0p4",
    "TMAX_30000",
    "ndiv_$NDiv",
    "reps_$NReps"
  ) -join '__'
}

function Get-ShortTag($job) {
  return "N$(Safe-Tag $job.N)_P12_$(Safe-Tag $job.P12)_B_$(Safe-Tag $job.B)"
}

function Write-Log([string]$Message) {
  $line = "{0}`t{1}" -f (Get-Date -Format s), $Message
  $line | Tee-Object -FilePath $ControllerLog -Append
}

function Build-Exe($job, [string]$Exe) {
  $cc = Get-Compiler
  $flags = @(
    '-O3','-std=c90','-pedantic','-Wall','-Wextra',
    "-DN1=$($job.N)",
    "-DN2=$($job.N)",
    '-DP11=0.9',
    "-DP12=$($job.P12)",
    '-DP22=0.9',
    "-DB=$($job.B)",
    '-DR=0',
    '-DE=-0.4',
    '-DT_MCS=1000',
    '-DT_MAX=30000',
    '-DW=2000',
    "-DN_INI_NDIV=$NDiv",
    "-DN_INI_COND=$NReps",
    '-DUPDATE_RULE=0',
    '-I', $Base,
    '-I', "$Base/core",
    '-I', "$Base/apps/well_mixed_limit"
  )
  $core = @(
    "$Base/core/rng.c",
    "$Base/core/graph.c",
    "$Base/core/state.c",
    "$Base/core/payoff.c",
    "$Base/core/dynamics.c",
    "$Base/core/sim.c",
    "$Base/core/utils.c",
    "$Base/core/io.c"
  )
  $src = @(
    "$Base/apps/well_mixed_limit/run_initial_plane_scan.c",
    "$Base/apps/well_mixed_limit/scan_initial_plane.c"
  )
  & $cc @flags @core @src '-lm' '-o' $Exe
  if ($LASTEXITCODE -ne 0) { throw "Fallo compilando $Exe" }
}

function Run-InitialPlane($job) {
  $tag = Get-RunTag $job
  $output = Join-Path $RawDir "initial_plane__$tag.txt"
  $partsDir = Join-Path $PartsRoot (Get-ShortTag $job)
  $exe = Join-Path $BuildDir 'run_initial_plane_extra.exe'

  if ($SkipExisting -and (Test-Path -LiteralPath $output) -and ((Get-Item -LiteralPath $output).Length -gt 0)) {
    Write-Log "SKIP $tag"
    return
  }

  New-Item -ItemType Directory -Force -Path $partsDir | Out-Null
  Get-ChildItem -LiteralPath $partsDir -Filter 'part_*.txt' -ErrorAction SilentlyContinue | Remove-Item -Force

  Write-Log "BUILD $tag"
  Build-Exe $job $exe

  Write-Log "START $tag"
  $totalIx = $NDiv + 1
  $jobs = [Math]::Min($ChunkJobs, $totalIx)
  $chunk = [int][Math]::Ceiling($totalIx / [double]$jobs)
  $processes = @()
  $parts = @()

  for ($j = 0; $j -lt $jobs; $j++) {
    $ixMin = $j * $chunk
    $ixMax = [Math]::Min($NDiv, (($j + 1) * $chunk) - 1)
    if ($ixMin -gt $ixMax) { continue }

    $part = Join-Path $partsDir ("part_{0:D3}_ix_{1:D3}_{2:D3}.txt" -f $j,$ixMin,$ixMax)
    $parts += $part
    $processes += Start-Process -FilePath $exe -ArgumentList @($ixMin, $ixMax, $part, $NDiv, $NReps) `
      -WorkingDirectory $Repo -WindowStyle Hidden -PassThru
  }

  foreach ($p in $processes) {
    $p.WaitForExit()
    if ($p.ExitCode -ne 0) { throw "Proceso $($p.Id) fallo con codigo $($p.ExitCode) en $tag" }
  }

  Remove-Item -LiteralPath $output -ErrorAction SilentlyContinue
  New-Item -ItemType File -Path $output -Force | Out-Null
  $first = $true
  foreach ($part in $parts) {
    if (!(Test-Path -LiteralPath $part)) { throw "No existe parcial esperado: $part" }
    if ($first) {
      Get-Content -LiteralPath $part | Add-Content -LiteralPath $output
      $first = $false
    } else {
      Get-Content -LiteralPath $part | Where-Object { $_ -and $_[0] -ne '#' } | Add-Content -LiteralPath $output
    }
  }

  Write-Log "END $tag output=$output"
}

"index`tN`tP11`tP12`tP22`tB`tR`tE`tT_MAX`tndiv`treps`toutput" |
  Set-Content -Encoding ASCII -LiteralPath $Manifest
"time`tmessage" | Set-Content -Encoding ASCII -LiteralPath $ControllerLog

$jobsToRun = @()
foreach ($n in @('50','75','125','150','250','300','350')) {
  foreach ($p12 in @('0.1','0.3')) {
    foreach ($b in @('1.174','1.3')) {
      $jobsToRun += [pscustomobject]@{ N = $n; P12 = $p12; B = $b }
    }
  }
}

for ($i = 0; $i -lt $jobsToRun.Count; $i++) {
  $job = $jobsToRun[$i]
  $tag = Get-RunTag $job
  $output = Join-Path $RawDir "initial_plane__$tag.txt"
  ("{0}`t{1}`t0.9`t{2}`t0.9`t{3}`t0`t-0.4`t30000`t{4}`t{5}`t{6}" -f
    ($i + 1), $job.N, $job.P12, $job.B, $NDiv, $NReps, $output) |
    Add-Content -Encoding ASCII -LiteralPath $Manifest
}

Write-Log "prepared simulations=$($jobsToRun.Count) ChunkJobs=$ChunkJobs NDiv=$NDiv NReps=$NReps"

foreach ($job in $jobsToRun) {
  Run-InitialPlane $job
}

Write-Log "all done"
