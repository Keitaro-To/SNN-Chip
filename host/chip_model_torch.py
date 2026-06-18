from __future__ import annotations

import torch
import torch.nn as nn


class ChipModelTorch(nn.Module):
  """Train float weights; quantize to int8 on export."""

  def __init__(
      self,
      n_exc: int = 162,
      n_neurons: int = 40,
      scale: float = 64.0,
  ) -> None:
    super().__init__()
    self.n_exc = n_exc
    self.n_neurons = n_neurons
    self.scale = scale
    self.weight_f = nn.Parameter(torch.randn(n_exc, n_neurons) * 0.02)

  def forward(self, spikes: torch.Tensor) -> torch.Tensor:
    acts = spikes @ self.weight_f
    return acts[:, 20:].sum(dim=1) - acts[:, :20].sum(dim=1)

  def export_int8_weights(self) -> torch.Tensor:
    return torch.clamp(torch.round(self.weight_f.detach() * self.scale), -128, 127).to(torch.int8)
