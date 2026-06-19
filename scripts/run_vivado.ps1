<#
.SYNOPSIS
  Vivado batch runner for network_uart (XSim / synth+impl+bitstream).

.EXAMPLE
  .\scripts\run_vivado.ps1 xsim
  .\scripts\run_vivado.ps1 build
  .\scripts\run_vivado.ps1 all
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('xsim', 'build', 'all')]
  [string]$Action = 'all',

  [string]$Vivado = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$VivadoDir = Join-Path $RepoRoot 'scripts\vivado'

function Resolve-Vivado {
  param([string]$Override)
  if ($Override -and (Test-Path $Override)) { return $Override }

  $candidates = @(
    'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat',
    'C:\Xilinx\Vivado\2025.2\bin\vivado.bat',
    'C:\Xilinx\Vivado\2024.2\bin\vivado.bat'
  )
  foreach ($c in $candidates) {
    if (Test-Path $c) { return $c }
  }

  $cmd = Get-Command vivado -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }

  throw 'vivado.bat not found. Pass -Vivado <path\to\vivado.bat>'
}

function Invoke-VivadoTcl {
  param(
    [string]$VivadoExe,
    [string]$TclScript
  )
  $log = Join-Path $RepoRoot ("fpga\build\{0}.log" -f ([IO.Path]::GetFileNameWithoutExtension($TclScript)))
  $logDir = Split-Path $log -Parent
  if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
  }

  Write-Host "[vivado] $TclScript -> $log" -ForegroundColor Cyan
  Push-Location $RepoRoot
  try {
    & $VivadoExe -mode batch -notrace -log $log -source $TclScript
    if ($LASTEXITCODE -ne 0) {
      throw "Vivado failed (exit=$LASTEXITCODE). See $log"
    }
  } finally {
    Pop-Location
  }
  Write-Host "[vivado] OK" -ForegroundColor Green
}

$vivadoExe = Resolve-Vivado -Override $Vivado

# Ensure ROM init files exist before Vivado.
$hexRtl = Join-Path $RepoRoot 'rtl\mem\rom_exc_weights.hex'
if (-not (Test-Path $hexRtl)) {
  Write-Host "[prep] generating ROM weights" -ForegroundColor Yellow
  python (Join-Path $RepoRoot 'scripts\weights_to_rom.py') `
    --weights (Join-Path $RepoRoot 'rtl\host\data\weights_seed_0.npy')
}

switch ($Action) {
  'xsim' {
    Invoke-VivadoTcl -VivadoExe $vivadoExe -TclScript (Join-Path $VivadoDir 'xsim.tcl')
  }
  'build' {
    Invoke-VivadoTcl -VivadoExe $vivadoExe -TclScript (Join-Path $VivadoDir 'build.tcl')
  }
  'all' {
    Invoke-VivadoTcl -VivadoExe $vivadoExe -TclScript (Join-Path $VivadoDir 'xsim.tcl')
    Invoke-VivadoTcl -VivadoExe $vivadoExe -TclScript (Join-Path $VivadoDir 'build.tcl')
  }
}
