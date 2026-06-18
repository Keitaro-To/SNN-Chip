from __future__ import annotations

import numpy as np

from host.config import load_config


class MnistBinaryDecoder:
    """Decode 40 output spikes: neurons 0-19 = class 0, 20-39 = class 1."""

    def __init__(self, config: dict | None = None) -> None:
        self.cfg = config or load_config()
        self.n_neurons = int(self.cfg["n_neurons"])
        dec = self.cfg["decoder"]
        self.class0 = list(dec["class0_neurons"])
        self.class1 = list(dec["class1_neurons"])

    def decode(self, out_spikes: np.ndarray | int) -> int:
        if isinstance(out_spikes, int):
            bits = np.array([(out_spikes >> i) & 1 for i in range(self.n_neurons)], dtype=np.uint8)
        else:
            bits = np.asarray(out_spikes, dtype=np.uint8).reshape(-1)
        c0 = int(bits[self.class0].sum())
        c1 = int(bits[self.class1].sum())
        return 1 if c1 > c0 else 0

    def logits(self, out_spikes: np.ndarray) -> float:
        bits = np.asarray(out_spikes, dtype=np.uint8).reshape(-1)
        return float(bits[self.class1].sum() - bits[self.class0].sum())
