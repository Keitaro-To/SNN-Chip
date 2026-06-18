#!/usr/bin/env python3
"""Convert excitatory weight matrix to ROM init files for simulation and Vivado.

Expected weight array shape: (n_exc_inputs, n_neurons), signed int8.
Each ROM address (input index) stores one row packed MSB-first per neuron
(neuron n occupies bits [n*8+7 : n*8]).
"""

from __future__ import annotations

import argparse
import pickle
import sys
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WEIGHTS = REPO_ROOT / "host" / "data" / "weights.pkl"
FALLBACK_WEIGHTS = REPO_ROOT / "rtl" / "host" / "data" / "weights_seed_0.pkl"
DEFAULT_PKL_CONN = "ES_EA_conn"
HEX_OUT = REPO_ROOT / "sim" / "mem" / "rom_exc_weights.hex"
COE_OUT = REPO_ROOT / "sim" / "mem" / "rom_exc_weights.coe"


class StubUnpickler(pickle.Unpickler):
    """Load pickles that reference training-time `network.*` classes."""

    def find_class(self, module: str, name: str) -> type:
        if module.startswith("network"):
            return type(name, (), {})
        return super().find_class(module, name)


def resolve_weights_path(path: Path) -> Path:
    if path.exists():
        return path
    if FALLBACK_WEIGHTS.exists():
        print(f"note: using {FALLBACK_WEIGHTS}")
        return FALLBACK_WEIGHTS
    return path


def pack_row(row: np.ndarray, n_neurons: int, weight_width: int = 8) -> int:
    value = 0
    for n in range(n_neurons):
        w = int(row[n])
        if w < -(1 << (weight_width - 1)) or w >= (1 << (weight_width - 1)):
            raise ValueError(f"weight {w} out of signed {weight_width}-bit range")
        if w < 0:
            w = (1 << weight_width) + w
        value |= w << (n * weight_width)
    return value


def write_hex(weights: np.ndarray, addr_width: int, path: Path) -> None:
    n_inputs, n_neurons = weights.shape
    depth = 1 << addr_width
    width_bits = n_neurons * 8
    hex_digits = (width_bits + 3) // 4
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as f:
        for addr in range(depth):
            if addr < n_inputs:
                packed = pack_row(weights[addr], n_neurons)
            else:
                packed = 0
            f.write(f"{packed:0{hex_digits}x}\n")
    print(f"wrote {path} ({depth} entries x {width_bits} bits)")


def write_coe(weights: np.ndarray, addr_width: int, path: Path) -> None:
    n_inputs, n_neurons = weights.shape
    depth = 1 << addr_width
    width_bits = n_neurons * 8
    hex_digits = (width_bits + 3) // 4
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="ascii") as f:
        f.write("memory_initialization_radix=16;\n")
        f.write("memory_initialization_vector=\n")
        lines = []
        for addr in range(depth):
            if addr < n_inputs:
                packed = pack_row(weights[addr], n_neurons)
            else:
                packed = 0
            suffix = "," if addr < depth - 1 else ";"
            lines.append(f"{packed:0{hex_digits}x}{suffix}")
        f.write("\n".join(lines))
        f.write("\n")
    print(f"wrote {path}")


def make_template(n_exc_inputs: int, n_neurons: int, seed: int) -> np.ndarray:
    rng = np.random.default_rng(seed)
    weights = np.full((n_exc_inputs, n_neurons), 16, dtype=np.int8)
    # Slight structure: first half inputs bias left-readout neurons, second half right.
    half = n_exc_inputs // 2
    for inp in range(n_exc_inputs):
        if inp < half:
            weights[inp, : n_neurons // 2] = rng.integers(8, 24, size=n_neurons // 2, dtype=np.int8)
        else:
            weights[inp, n_neurons // 2 :] = rng.integers(8, 24, size=n_neurons // 2, dtype=np.int8)
    return weights


def extract_array(obj: object, pkl_key: str | None) -> np.ndarray:
    if pkl_key is not None:
        if not isinstance(obj, dict):
            raise ValueError(f"--pkl-key {pkl_key!r} given but pickle root is {type(obj).__name__}")
        if pkl_key not in obj:
            raise ValueError(f"key {pkl_key!r} not in pickle (keys: {list(obj.keys())})")
        obj = obj[pkl_key]

    if hasattr(obj, "detach"):
        obj = obj.detach().cpu().numpy()

    return np.asarray(obj)


def orient_weights(arr: np.ndarray, n_exc_inputs: int, n_neurons: int) -> np.ndarray:
    if arr.ndim != 2:
        raise ValueError(f"expected 2-D weights, got shape {arr.shape}")

    if arr.shape == (n_exc_inputs, n_neurons):
        return arr

    if arr.shape == (n_neurons, n_exc_inputs):
        print(f"note: transposing weights from {arr.shape} to ({n_exc_inputs}, {n_neurons})")
        return arr.T

    raise ValueError(
        f"weights shape {arr.shape} does not match "
        f"({n_exc_inputs}, {n_neurons}) or ({n_neurons}, {n_exc_inputs})"
    )


def extract_from_pickle(obj: object, pkl_key: str | None, pkl_conn: str | None) -> np.ndarray:
    if not isinstance(obj, dict):
        return extract_array(obj, pkl_key)

    if pkl_key is not None:
        return extract_array(obj, pkl_key)

    conn_name = pkl_conn or DEFAULT_PKL_CONN
    if conn_name in obj:
        conn = obj[conn_name]
        if hasattr(conn, "W"):
            print(f"note: using pickle connection {conn_name!r} (.W)")
            return np.asarray(conn.W)
        return np.asarray(conn)

    raise ValueError(
        f"could not find weights in pickle; tried connection {conn_name!r}. "
        f"available keys: {list(obj.keys())}"
    )


def quantize_weights(arr: np.ndarray, scale: float) -> np.ndarray:
    if np.issubdtype(arr.dtype, np.floating):
        q = np.round(arr * scale)
        if q.min() < -128 or q.max() > 127:
            raise ValueError(
                f"quantized weights out of int8 range [{q.min()}, {q.max()}] "
                f"with scale={scale}; try a smaller --scale"
            )
        print(
            f"note: quantized float weights with scale={scale} "
            f"-> int8 range [{int(q.min())}, {int(q.max())}]"
        )
        return q.astype(np.int8, copy=False)
    return np.round(arr).astype(np.int8, copy=False)


def load_weights(
    path: Path,
    pkl_key: str | None,
    pkl_conn: str | None,
    scale: float,
    n_exc_inputs: int,
    n_neurons: int,
) -> np.ndarray:
    suffix = path.suffix.lower()
    if suffix == ".npy":
        arr = np.load(path)
    elif suffix == ".csv":
        arr = np.loadtxt(path, delimiter=",", dtype=np.int8)
    elif suffix in {".pkl", ".pickle"}:
        with path.open("rb") as f:
            arr = extract_from_pickle(StubUnpickler(f).load(), pkl_key, pkl_conn)
    else:
        raise ValueError(f"unsupported weights format: {path.suffix} (use .npy, .csv, .pkl)")

    arr = orient_weights(arr, n_exc_inputs, n_neurons)
    return quantize_weights(arr, scale)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--weights", type=Path, default=DEFAULT_WEIGHTS)
    parser.add_argument("--hex-out", type=Path, default=HEX_OUT)
    parser.add_argument("--coe-out", type=Path, default=COE_OUT)
    parser.add_argument("--n-exc-inputs", type=int, default=162)
    parser.add_argument("--n-neurons", type=int, default=40)
    parser.add_argument("--addr-width", type=int, default=8)
    parser.add_argument("--generate-template", action="store_true")
    parser.add_argument("--seed", type=int, default=0)
    parser.add_argument(
        "--pkl-key",
        default=None,
        help="key inside a dict pickle (raw ndarray or tensor).",
    )
    parser.add_argument(
        "--pkl-conn",
        default=DEFAULT_PKL_CONN,
        help="Spiker+ SparseConnection name (default: ES_EA_conn, uses .W).",
    )
    parser.add_argument(
        "--scale",
        type=float,
        default=128.0,
        help="float-to-int8 scale for pickle weights (default: 128).",
    )
    args = parser.parse_args()
    args.weights = resolve_weights_path(args.weights)

    if args.generate_template or not args.weights.exists():
        weights = make_template(args.n_exc_inputs, args.n_neurons, args.seed)
        args.weights.parent.mkdir(parents=True, exist_ok=True)
        np.save(args.weights.with_suffix(".npy"), weights)
        print(f"wrote template weights {args.weights.with_suffix('.npy')} shape={weights.shape}")
    else:
        weights = load_weights(
            args.weights,
            args.pkl_key,
            args.pkl_conn,
            args.scale,
            args.n_exc_inputs,
            args.n_neurons,
        )

    if weights.shape != (args.n_exc_inputs, args.n_neurons):
        raise SystemExit(
            f"weights shape {weights.shape} != ({args.n_exc_inputs}, {args.n_neurons})"
        )

    write_hex(weights, args.addr_width, args.hex_out)
    write_coe(weights, args.addr_width, args.coe_out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
