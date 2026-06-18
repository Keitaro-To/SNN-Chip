from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import numpy as np
import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = REPO_ROOT / "host" / "config.yaml"


def load_config(path: Path | None = None) -> dict[str, Any]:
    cfg_path = path or DEFAULT_CONFIG
    with cfg_path.open(encoding="utf-8") as f:
        cfg = yaml.safe_load(f)
    port_override = os.environ.get("SNN_UART_PORT")
    if port_override:
        cfg.setdefault("uart", {})["port"] = port_override
    return cfg


def spikes_to_int(spikes: np.ndarray | list[int] | int) -> int:
    if isinstance(spikes, int):
        return spikes
    arr = np.asarray(spikes, dtype=np.uint8).reshape(-1)
    value = 0
    for i, bit in enumerate(arr):
        if bit:
            value |= 1 << i
    return value


def int_to_spikes(value: int, width: int) -> np.ndarray:
    return np.array([(value >> i) & 1 for i in range(width)], dtype=np.uint8)


def pack_bits_lsb_first(bits: np.ndarray, nbytes: int) -> bytes:
    out = bytearray(nbytes)
    for i in range(bits.size):
        if bits[i]:
            out[i // 8] |= 1 << (i % 8)
    return bytes(out)


def unpack_bits_lsb_first(data: bytes, width: int) -> np.ndarray:
    bits = np.zeros(width, dtype=np.uint8)
    for i in range(width):
        bits[i] = (data[i // 8] >> (i % 8)) & 1
    return bits
