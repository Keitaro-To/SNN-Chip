from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np

from host.config import load_config


@dataclass(frozen=True)
class ChipParams:
    n_exc_inputs: int = 162
    n_neurons: int = 40
    n_cycles: int = 5
    exc_cnt_bitwidth: int = 8
    v_th: int = 16
    shift: int = 3
    neuron_bit_width: int = 16

    @classmethod
    def from_config(cls, config: dict | None = None, config_path: Path | None = None) -> ChipParams:
        if config is None:
            config = load_config(config_path) if config_path else load_config(
                Path(__file__).resolve().parent / "config_mnist_binary.yaml"
            )
        chip = config.get("chip", {})
        return cls(
            n_exc_inputs=int(config["n_exc_inputs"]),
            n_neurons=int(config["n_neurons"]),
            n_cycles=int(config["n_cycles"]),
            exc_cnt_bitwidth=int(config.get("exc_cnt_bitwidth", 8)),
            v_th=int(chip.get("v_th", 16)),
            shift=int(chip.get("shift", 3)),
            neuron_bit_width=int(chip.get("neuron_bit_width", 16)),
        )


def exc_scan_indices(n_exc_inputs: int, cnt_bitwidth: int) -> list[int]:
    """Counter walk matching multi_input_dp exc_cnt (rst=n-1, stop at n-2)."""
    mask = (1 << cnt_bitwidth) - 1
    cnt = n_exc_inputs - 1
    order: list[int] = []
    while True:
        order.append(cnt)
        if cnt == n_exc_inputs - 2:
            break
        cnt = (cnt + 1) & mask
    return order


def _clip_membrane(v: np.ndarray, bit_width: int) -> np.ndarray:
    lo = -(1 << (bit_width - 1))
    hi = (1 << (bit_width - 1)) - 1
    return np.clip(v, lo, hi)


def _sample_phase(v: np.ndarray, v_th: int, shift: int, bit_width: int) -> tuple[np.ndarray, np.ndarray]:
    """MI_SAMPLE with exc=inh=1: fire (subtractive) or leak."""
    v = v.astype(np.int32, copy=True)
    out_spikes = np.zeros(v.shape, dtype=np.uint8)
    for n in range(v.size):
        if v[n] > v_th:
            v[n] -= v_th
            out_spikes[n] = 1
        else:
            v[n] -= v[n] >> shift
    return _clip_membrane(v, bit_width), out_spikes


def chip_forward(
    spikes: np.ndarray,
    weights: np.ndarray,
    params: ChipParams | None = None,
) -> np.ndarray:
    """
    RTL-aligned exc-only network forward (one inference).

    spikes: (n_exc,) uint8/bool
    weights: (n_exc, n_neurons) int8/float — ROM row index = exc_cnt
    returns: (n_neurons,) uint8 output spikes (last barrier sample)
    """
    p = params or ChipParams()
    spikes = np.asarray(spikes, dtype=np.uint8).reshape(-1)
    weights = np.asarray(weights, dtype=np.int32)
    if spikes.size != p.n_exc_inputs:
        raise ValueError(f"expected {p.n_exc_inputs} input spikes, got {spikes.size}")
    if weights.shape != (p.n_exc_inputs, p.n_neurons):
        raise ValueError(
            f"expected weights shape ({p.n_exc_inputs}, {p.n_neurons}), got {weights.shape}"
        )

    scan = exc_scan_indices(p.n_exc_inputs, p.exc_cnt_bitwidth)
    v = np.zeros(p.n_neurons, dtype=np.int32)
    barrier = np.zeros(p.n_neurons, dtype=np.uint8)

    for _ in range(p.n_cycles + 1):
        v, sample_spikes = _sample_phase(v, p.v_th, p.shift, p.neuron_bit_width)
        for cnt in scan:
            if cnt < p.n_exc_inputs and spikes[cnt]:
                rom_row = cnt + 1
                if rom_row < p.n_exc_inputs:
                    v += weights[rom_row]
        v = _clip_membrane(v, p.neuron_bit_width)
        barrier = (v > p.v_th).astype(np.uint8)

    return barrier


def spike_class_logits(out_spikes: np.ndarray, class0_idx: list[int], class1_idx: list[int]) -> float:
    bits = np.asarray(out_spikes, dtype=np.uint8).reshape(-1)
    c0 = int(bits[class0_idx].sum())
    c1 = int(bits[class1_idx].sum())
    return float(c1 - c0)


def load_weights_from_hex(path: Path, n_exc: int, n_neurons: int) -> np.ndarray:
    """Unpack sim/mem/rom_exc_weights.hex into (n_exc, n_neurons) int8."""
    weights = np.zeros((n_exc, n_neurons), dtype=np.int8)
    lines = path.read_text(encoding="ascii").splitlines()
    for addr in range(n_exc):
        packed = int(lines[addr], 16)
        for n in range(n_neurons):
            w = (packed >> (n * 8)) & 0xFF
            if w >= 128:
                w -= 256
            weights[addr, n] = np.int8(w)
    return weights
