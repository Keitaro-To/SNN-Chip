from __future__ import annotations

import numpy as np

from host.config import load_config


class ReadoutDecoder:
    """Decode output neuron spikes into CartPole action {0=left, 1=right}."""

    def __init__(self, config: dict | None = None) -> None:
        self.cfg = config or load_config()
        self.n_neurons = int(self.cfg["n_neurons"])
        self.left = list(self.cfg["decoder"]["left_neurons"])
        self.right = list(self.cfg["decoder"]["right_neurons"])

    def decode(self, out_spikes: np.ndarray | int) -> int:
        if isinstance(out_spikes, int):
            bits = np.array([(out_spikes >> i) & 1 for i in range(self.n_neurons)], dtype=np.uint8)
        else:
            bits = np.asarray(out_spikes, dtype=np.uint8).reshape(-1)
            if bits.size < self.n_neurons:
                raise ValueError(f"expected {self.n_neurons} output bits, got {bits.size}")

        left_votes = int(bits[self.left].sum())
        right_votes = int(bits[self.right].sum())
        if right_votes > left_votes:
            return 1
        return 0
