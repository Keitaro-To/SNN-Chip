<#
.SYNOPSIS
  Icarus Verilog ベースの SNN プロジェクト用ビルド/シミュレーションランナー。

.DESCRIPTION
  sim/filelists/<TOP>.f を読み込み、コンパイル → vvp 実行 までを行う。
  GTKWave で波形を開く wave サブコマンドも提供する。

  実行は常に sim/build/ をカレントディレクトリにして行うため、
  filelist 内の相対パスは sim/build/ からの相対 (例: ../../rtl/...) で書く。

.EXAMPLE
  .\scripts\run.ps1 build barrier
  .\scripts\run.ps1 sim   barrier
  .\scripts\run.ps1 wave  barrier
  .\scripts\run.ps1 list
  .\scripts\run.ps1 clean
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [ValidateSet('build','sim','wave','list','clean','all')]
  [string]$Action = 'sim',

  [Parameter(Position=1)]
  [string]$Top = ''
)

$ErrorActionPreference = 'Stop'
# iverilog/vvp は stderr に警告を出すが、これを PowerShell が
# 終端エラー扱いしないように、native call 直前に Continue に切替える。

$RepoRoot   = Resolve-Path (Join-Path $PSScriptRoot '..')
$BuildDir   = Join-Path $RepoRoot 'sim\build'
$WavesDir   = Join-Path $RepoRoot 'sim\waves'
$FilelistsDir = Join-Path $RepoRoot 'sim\filelists'

function Ensure-Dirs {
  foreach ($d in @($BuildDir, $WavesDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
  }
}

function List-Targets {
  Get-ChildItem $FilelistsDir -Filter '*.f' |
    Where-Object { $_.BaseName -notin @('common','rtl_all') } |
    Select-Object -ExpandProperty BaseName |
    Sort-Object
}

function Require-Top {
  if ([string]::IsNullOrWhiteSpace($Top)) {
    Write-Host "TOP が未指定です。利用可能なターゲット:" -ForegroundColor Yellow
    List-Targets | ForEach-Object { Write-Host "  $_" }
    throw "Usage: .\scripts\run.ps1 <build|sim|wave> <TOP>"
  }
  $f = Join-Path $FilelistsDir "$Top.f"
  if (-not (Test-Path $f)) { throw "filelist が見つかりません: $f" }
  return $f
}

function Invoke-Build {
  $filelist = Require-Top
  Ensure-Dirs
  $vvp = Join-Path $BuildDir "$Top.vvp"

  Push-Location $BuildDir
  $prevEAP = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    Write-Host "[build] iverilog -g2012 -o $Top.vvp -f $filelist" -ForegroundColor Cyan
    & iverilog -g2012 -o "$Top.vvp" -f $filelist 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
      $ErrorActionPreference = $prevEAP
      throw "iverilog がエラーで終了 (exit=$LASTEXITCODE)"
    }
  } finally {
    $ErrorActionPreference = $prevEAP
    Pop-Location
  }
  Write-Host "[build] OK -> $vvp" -ForegroundColor Green
}

function Invoke-Sim {
  Invoke-Build
  Push-Location $BuildDir
  $prevEAP = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    Write-Host "[sim]   vvp $Top.vvp" -ForegroundColor Cyan
    & vvp "$Top.vvp" 2>&1 | ForEach-Object { Write-Host $_ }
    $code = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $prevEAP
    Pop-Location
  }
  # VCD が生成されていれば waves/ に移動
  $vcd = Join-Path $BuildDir "${Top}_tb.vcd"
  if (Test-Path $vcd) {
    $dest = Join-Path $WavesDir (Split-Path $vcd -Leaf)
    Move-Item -Force $vcd $dest
    Write-Host "[sim]   VCD -> $dest" -ForegroundColor Green
  }
  if ($code -ne 0) { throw "vvp がエラーで終了 (exit=$code)" }
}

function Invoke-Wave {
  $filelist = Require-Top
  $vcd = Join-Path $WavesDir "${Top}_tb.vcd"
  if (-not (Test-Path $vcd)) {
    Write-Host "[wave]  VCD が未生成のためまずシミュレーションを実行します" -ForegroundColor Yellow
    Invoke-Sim
  }
  if (-not (Test-Path $vcd)) {
    throw ("VCD が生成されませんでした。テストベンチに " + '$dumpfile/$dumpvars' + " が必要です: $vcd")
  }
  Write-Host "[wave]  gtkwave $vcd" -ForegroundColor Cyan
  Start-Process gtkwave -ArgumentList @($vcd)
}

function Invoke-Clean {
  if (Test-Path $BuildDir) {
    Get-ChildItem $BuildDir -Exclude '.gitkeep' -Force | Remove-Item -Recurse -Force
  }
  if (Test-Path $WavesDir) {
    Get-ChildItem $WavesDir -Exclude '.gitkeep' -Force | Remove-Item -Recurse -Force
  }
  Write-Host "[clean] sim/build, sim/waves をクリア" -ForegroundColor Green
}

function Invoke-All {
  $targets = List-Targets
  $results = @()
  foreach ($t in $targets) {
    try {
      $script:Top = $t
      Invoke-Sim
      $results += [pscustomobject]@{ Top=$t; Status='OK' }
    } catch {
      $results += [pscustomobject]@{ Top=$t; Status="FAIL: $_" }
    }
  }
  Write-Host ""
  Write-Host "=== Summary ===" -ForegroundColor Cyan
  $results | Format-Table -AutoSize
}

switch ($Action) {
  'build' { Invoke-Build }
  'sim'   { Invoke-Sim }
  'wave'  { Invoke-Wave }
  'list'  { List-Targets }
  'clean' { Invoke-Clean }
  'all'   { Invoke-All }
}
