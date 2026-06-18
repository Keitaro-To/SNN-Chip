from __future__ import annotations

from pathlib import Path

import numpy as np

from host.config import load_config

try:
    from PIL import Image
except ImportError:  # pragma: no cover
    Image = None


class ImageEncoder:
    """Resize image to 9x18 and threshold to 162-bit spike vector."""

    def __init__(self, config: dict | None = None, config_path: Path | None = None) -> None:
        if config is None:
            config = load_config(config_path) if config_path else load_config(
                Path(__file__).resolve().parents[1] / "config_mnist_binary.yaml"
            )
        enc = config["encoder"]
        self.n_exc = int(config["n_exc_inputs"])
        self.height = int(enc["image_height"])
        self.width = int(enc["image_width"])
        self.threshold = float(enc["threshold"])
        if self.height * self.width != self.n_exc:
            raise ValueError(
                f"image_height*image_width ({self.height*self.width}) "
                f"must equal n_exc_inputs ({self.n_exc})"
            )

    def encode(self, image: np.ndarray) -> np.ndarray:
        if Image is None:
            raise ImportError("Pillow is required for ImageEncoder (pip install pillow)")

        arr = np.asarray(image, dtype=np.float64)
        if arr.ndim == 3:
            arr = arr[..., 0]
        arr = np.clip(arr, 0.0, 1.0)

        pil = Image.fromarray((arr * 255.0).astype(np.uint8))
        small = np.asarray(
            pil.resize((self.width, self.height), Image.Resampling.BILINEAR),
            dtype=np.float64,
        ) / 255.0

        spikes = (small.reshape(-1) > self.threshold).astype(np.uint8)
        return spikes
