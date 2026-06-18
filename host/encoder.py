from __future__ import annotations

import numpy as np

from host.config import load_config


class PopulationEncoder:
    """Map CartPole observation to a fixed-width binary spike vector."""

    def __init__(self, config: dict | None = None) -> None:
        self.cfg = config or load_config()
        self.n_exc = int(self.cfg["n_exc_inputs"])
        self.bins_per_dim = int(self.cfg["bins_per_dim"])
        self.dims = self.cfg["dims"]
        self.sigma_bins = float(self.cfg["encoder"]["sigma_bins"])
        if self.bins_per_dim * len(self.dims) > self.n_exc:
            raise ValueError("bins_per_dim * dims exceeds n_exc_inputs")

    def _dim_centers(self, low: float, high: float) -> np.ndarray:
        return np.linspace(low, high, self.bins_per_dim, dtype=np.float64)

    def encode(self, obs: np.ndarray) -> np.ndarray:
        obs = np.asarray(obs, dtype=np.float64).reshape(-1)
        if obs.size != len(self.dims):
            raise ValueError(f"expected {len(self.dims)}-D observation, got {obs.size}")

        spikes = np.zeros(self.n_exc, dtype=np.uint8)
        offset = 0
        for d, spec in enumerate(self.dims):
            centers = self._dim_centers(spec["low"], spec["high"])
            span = spec["high"] - spec["low"]
            sigma = (span / max(self.bins_per_dim - 1, 1)) * self.sigma_bins
            dist = np.abs(obs[d] - centers)
            active = dist <= sigma
            spikes[offset : offset + self.bins_per_dim] = active.astype(np.uint8)
            offset += self.bins_per_dim
        return spikes
