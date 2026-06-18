#!/usr/bin/env python3
"""Train MNIST binary (0 vs 1) weights for the 162->40 chip."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
import yaml
from torch.utils.data import DataLoader, Subset
from torchvision import datasets, transforms

from host.chip_model import ChipParams, chip_forward
from host.chip_model_torch import ChipModelTorch
from host.encoders.image_encoder import ImageEncoder

REPO_ROOT = Path(__file__).resolve().parents[1]


def load_mnist_config(path: Path) -> dict:
    with path.open(encoding="utf-8") as f:
        return yaml.safe_load(f)


def filter_binary(dataset, classes: list[int]) -> Subset:
    labels = dataset.targets.numpy() if hasattr(dataset.targets, "numpy") else np.asarray(dataset.targets)
    idx = np.where(np.isin(labels, classes))[0]
    return Subset(dataset, idx.tolist())


def main() -> int:
    parser = argparse.ArgumentParser(description="Train MNIST 0/1 chip weights")
    parser.add_argument("--config", type=Path, default=REPO_ROOT / "host" / "config_mnist_binary.yaml")
    parser.add_argument("--epochs", type=int, default=None)
    parser.add_argument("--batch-size", type=int, default=None)
    parser.add_argument("--lr", type=float, default=None)
    parser.add_argument("--scale", type=float, default=None)
    parser.add_argument("--max-samples", type=int, default=0, help="limit train samples (0=all)")
    parser.add_argument("--out", type=Path, default=None)
    args = parser.parse_args()

    cfg = load_mnist_config(args.config)
    train_cfg = cfg["train"]
    epochs = args.epochs or int(train_cfg["epochs"])
    batch_size = args.batch_size or int(train_cfg["batch_size"])
    lr = args.lr or float(train_cfg["lr"])
    scale = args.scale or float(train_cfg["weight_scale"])
    classes = [int(c) for c in train_cfg["classes"]]
    out_path = args.out or (REPO_ROOT / cfg["paths"]["weights_out"])

    encoder = ImageEncoder(cfg)
    params = ChipParams.from_config(cfg)

    transform = transforms.ToTensor()
    root = REPO_ROOT / "host" / "data" / "mnist"
    train_ds = filter_binary(datasets.MNIST(root, train=True, download=True, transform=transform), classes)
    if args.max_samples > 0:
        train_ds = Subset(train_ds, list(range(min(args.max_samples, len(train_ds)))))

    model = ChipModelTorch(
        n_exc=params.n_exc_inputs,
        n_neurons=params.n_neurons,
        scale=scale,
    )
    opt = torch.optim.Adam(model.parameters(), lr=lr)

    loader = DataLoader(train_ds, batch_size=batch_size, shuffle=True)

    label_map = {classes[0]: 0, classes[1]: 1}
    best_acc = 0.0
    best_w: np.ndarray | None = None

    for epoch in range(epochs):
        model.train()
        total_loss = 0.0
        correct = 0
        total = 0
        for images, labels in loader:
            batch_spikes = []
            for img in images:
                batch_spikes.append(encoder.encode(img.squeeze(0).numpy()))
            spikes = torch.tensor(np.stack(batch_spikes), dtype=torch.float32)
            targets = torch.tensor([label_map[int(y)] for y in labels], dtype=torch.float32)

            opt.zero_grad()
            logits = model(spikes)
            loss = F.binary_cross_entropy_with_logits(logits, targets)
            loss.backward()
            opt.step()

            total_loss += float(loss.item()) * spikes.size(0)
            preds = (logits > 0).to(torch.int32)
            correct += int((preds == targets.to(torch.int32)).sum())
            total += spikes.size(0)

        acc = correct / max(total, 1)
        print(f"epoch {epoch + 1}/{epochs} loss={total_loss / total:.4f} acc={acc:.3f}")
        if acc >= best_acc:
            best_acc = acc
            best_w = model.export_int8_weights().cpu().numpy()

    if best_w is None:
        best_w = model.export_int8_weights().cpu().numpy()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    np.save(out_path, best_w.astype(np.int8))
    print(f"saved {out_path} shape={best_w.shape} best_acc={best_acc:.3f} scale={scale}")

    # quick chip_model sanity on one batch
    sample_spikes = encoder.encode(np.zeros((9, 18)))
    _ = chip_forward(sample_spikes, best_w, params)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
