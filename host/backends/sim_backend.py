from __future__ import annotations

import subprocess
import time
from abc import ABC, abstractmethod
from pathlib import Path

import numpy as np

from host.config import REPO_ROOT, load_config, spikes_to_int


class InferenceBackend(ABC):
    @abstractmethod
    def infer(self, spikes: np.ndarray) -> np.ndarray:
        raise NotImplementedError


class SimBackend(InferenceBackend):
    """Run one inference via iverilog network_infer_tb and file handshake."""

    def __init__(self, repo_root: Path | None = None) -> None:
        self.repo_root = repo_root or REPO_ROOT
        self.build_dir = self.repo_root / "sim" / "build"
        self.infer_in = self.build_dir / "infer_in.hex"
        self.infer_out = self.build_dir / "infer_out.hex"
        self._ensure_built()

    def _ensure_built(self) -> None:
        script = self.repo_root / "scripts" / "run.ps1"
        subprocess.run(
            ["powershell", "-File", str(script), "build", "network_infer"],
            cwd=self.repo_root,
            check=True,
        )

    def infer(self, spikes: np.ndarray) -> np.ndarray:
        cfg = load_config()
        width = int(cfg["n_neurons"])
        packed = spikes_to_int(spikes)
        self.build_dir.mkdir(parents=True, exist_ok=True)
        self.infer_in.write_text(f"{packed:x}\n", encoding="ascii")
        if self.infer_out.exists():
            self.infer_out.unlink()

        script = self.repo_root / "scripts" / "run.ps1"
        subprocess.run(
            ["powershell", "-File", str(script), "sim", "network_infer"],
            cwd=self.repo_root,
            check=True,
        )

        deadline = time.time() + 60.0
        while not self.infer_out.exists():
            if time.time() > deadline:
                raise TimeoutError("network_infer simulation did not produce infer_out.hex")
            time.sleep(0.05)

        value = int(self.infer_out.read_text(encoding="ascii").strip(), 16)
        return np.array([(value >> i) & 1 for i in range(width)], dtype=np.uint8)
