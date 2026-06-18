from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from host.chip_model import ChipParams, chip_forward, load_weights_from_hex
from host.backends.sim_backend import SimBackend


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare chip_model vs SimBackend")
    parser.add_argument("--cases", type=int, default=3)
    args = parser.parse_args()

    params = ChipParams()
    n_exc = params.n_exc_inputs
    hex_path = REPO_ROOT / "sim" / "mem" / "rom_exc_weights.hex"
    weights = load_weights_from_hex(hex_path, n_exc, params.n_neurons)

    backend = SimBackend()
    mismatches = 0
    for k in range(args.cases):
        spikes = np.zeros(n_exc, dtype=np.uint8)
        spikes[k % n_exc] = 1
        if k > 0:
            spikes[(k * 7) % n_exc] = 1

        py_out = chip_forward(spikes, weights, params)
        rtl_out = backend.infer(spikes)
        if not np.array_equal(py_out, rtl_out):
            mismatches += 1
            print(f"case {k}: mismatch")
            print(f"  spikes_on={np.where(spikes)[0].tolist()}")
            print(f"  py  ={py_out.tolist()}")
            print(f"  rtl ={rtl_out.tolist()}")
        else:
            print(f"case {k}: OK  out={py_out.sum()} spikes")

    if mismatches:
        print(f"FAILED: {mismatches}/{args.cases} mismatches")
        return 1
    print("All cases match SimBackend")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
