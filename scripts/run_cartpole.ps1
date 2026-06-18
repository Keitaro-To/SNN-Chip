<#
.SYNOPSIS
  CartPole + SNN host runner and cocotb integration tests.

.EXAMPLE
  .\scripts\run_cartpole.ps1 sim --episodes 1
  .\scripts\run_cartpole.ps1 cocotb
  .\scripts\run_cartpole.ps1 uart --port COM3
#>

[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [ValidateSet('sim', 'cocotb', 'uart', 'weights')]
  [string]$Action = 'sim',

  [int]$Episodes = 1,
  [int]$MaxSteps = 200,
  [string]$Port = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

function Ensure-PythonDeps {
  python -c "import numpy, yaml" 2>$null
  if ($LASTEXITCODE -ne 0) { pip install numpy pyyaml }
  if ($Action -eq 'sim' -or $Action -eq 'uart') {
    python -c "import gymnasium" 2>$null
    if ($LASTEXITCODE -ne 0) { pip install gymnasium }
  }
  if ($Action -eq 'uart') {
    python -c "import serial" 2>$null
    if ($LASTEXITCODE -ne 0) { pip install pyserial }
  }
}

switch ($Action) {
  'weights' {
    python (Join-Path $RepoRoot 'scripts\weights_to_rom.py')
  }
  'sim' {
    Ensure-PythonDeps
    python (Join-Path $RepoRoot 'scripts\weights_to_rom.py')
    python (Join-Path $RepoRoot 'scripts\run_cartpole.py') --backend sim --episodes $Episodes --max-steps $MaxSteps --log-every 50
  }
  'uart' {
    Ensure-PythonDeps
    $args = @('--backend', 'uart', '--episodes', $Episodes, '--max-steps', $MaxSteps)
    if ($Port) { $env:SNN_UART_PORT = $Port }
    python (Join-Path $RepoRoot 'scripts\run_cartpole.py') @args
  }
  'cocotb' {
    python (Join-Path $RepoRoot 'scripts\weights_to_rom.py')
    python (Join-Path $RepoRoot 'scripts\run_cocotb.py')
  }
}
