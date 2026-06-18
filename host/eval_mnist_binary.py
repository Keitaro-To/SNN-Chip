#!/usr/bin/env python3
"""Evaluate MNIST binary classifier with chip_model and optional SimBackend."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import yaml
from torchvision import datasets, transforms

from host.backends.sim_backend import SimBackend
from host.chip_model import ChipParams, chip_forward
from host.encoders.image_encoder import ImageEncoder
from host.mnist_decoder import MnistBinaryDecoder

REPO_ROOT = Path(__file__).resolve().parents[1]


def load_config(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def main() -> int:
    parser = argparse.ArgumentParser(description="Evaluate MNIST 0/1 chip classifier")
    parser.add_argument("--config", type=Path, default=REPO_ROOT / "host" / "config_mnist_binary.yaml")
    parser.add_argument("--weights", type=Path, default=REPO_ROOT / "host" / "data" / "weights.npy")
    parser.add_argument("--backend", choices=["chip", "sim"], default="chip")
    parser.add_argument("--max-samples", type=int, default=0)
    args = parser.parse_args()

    cfg = load_config(args.config)
    classes = [int(c) for c in cfg["train"]["classes"]]
    encoder = ImageEncoder(cfg)
    decoder = MnistBinaryDecoder(cfg)
    params = ChipParams.from_config(cfg)

    weights = np.load(args.weights).astype(np.int8)
    if weights.shape != (params.n_exc_inputs, params.n_neurons):
        raise ValueError(f"bad weights shape {weights.shape}")

    backend = SimBackend() if args.backend == "sim" else None
    root = REPO_ROOT / "host" / "data" / "mnist"
    test_ds = datasets.MNIST(root, train=False, download=True, transform=transforms.ToTensor())

    labels = test_ds.targets.numpy()
    mask = np.isin(labels, classes)
    indices = np.where(mask)[0]
    if args.max_samples > 0:
        indices = indices[: args.max_samples]

    label_map = {classes[0]: 0, classes[1]: 1}
    conf = np.zeros((2, 2), dtype=np.int32)
    for i in indices:
        img, label = test_ds[int(i)]
        spikes = encoder.encode(img.squeeze(0).numpy())
        if backend is not None:
            out = backend.infer(spikes)
        else:
            out = chip_forward(spikes, weights, params)
        pred = decoder.decode(out)
        conf[label_map[int(label)], pred] += 1

    acc = np.trace(conf) / max(conf.sum(), 1)
    print(f"backend={args.backend} accuracy={acc:.3f} ({conf.sum()} samples)")
    print(f"confusion (rows=true 0,1 / cols=pred 0,1):\n{conf}")
    return 0 if acc >= 0.5 else 1


if __name__ == "__main__":
    raise SystemExit(main())
