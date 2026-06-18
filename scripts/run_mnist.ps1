<#
.SYNOPSIS
  MNIST binary (0 vs 1) training / eval / cocotb wrapper.

.EXAMPLE
  .\scripts\run_mnist.ps1 train
  .\scripts\run_mnist.ps1 train -Epochs 10 -MaxSamples 2000
  .\scripts\run_mnist.ps1 eval
  .\scripts\run_mnist.ps1 eval -Backend sim
  .\scripts\run_mnist.ps1 cocotb
  .\scripts\run_mnist.ps1 rom
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('train', 'eval', 'cocotb', 'rom', 'all')]
  [string]$Action = 'train',

  [int]$Epochs = 0,
  [int]$MaxSamples = 0,
  [double]$Scale = 0,
  [ValidateSet('chip', 'sim')]
  [string]$Backend = 'chip'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$env:PYTHONPATH = $RepoRoot.Path

function Invoke-Train {
  $args = @("$RepoRoot\host\train_mnist_binary.py")
  if ($Epochs -gt 0) { $args += @('--epochs', $Epochs) }
  if ($MaxSamples -gt 0) { $args += @('--max-samples', $MaxSamples) }
  if ($Scale -gt 0) { $args += @('--scale', $Scale) }
  python @args
}

function Invoke-Eval {
  $args = @("$RepoRoot\host\eval_mnist_binary.py", '--backend', $Backend)
  if ($MaxSamples -gt 0) { $args += @('--max-samples', $MaxSamples) }
  python @args
}

function Invoke-Rom {
  $weights = Join-Path $RepoRoot 'host\data\weights.npy'
  if (-not (Test-Path $weights)) {
    throw "weights not found: $weights (run train first)"
  }
  python "$RepoRoot\scripts\weights_to_rom.py" --weights $weights
}

function Invoke-Cocotb {
  Invoke-Rom
  python "$RepoRoot\scripts\run_cocotb.py" --module test_mnist_binary_infer
}

Push-Location $RepoRoot
try {
  switch ($Action) {
    'train'  { Invoke-Train }
    'eval'   { Invoke-Eval }
    'rom'    { Invoke-Rom }
    'cocotb' { Invoke-Cocotb }
    'all'    { Invoke-Train; Invoke-Rom; Invoke-Eval; Invoke-Cocotb }
  }
} finally {
  Pop-Location
}
