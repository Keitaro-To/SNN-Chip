import os
from pathlib import Path

import cocotb
import numpy as np
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

REPO_ROOT = Path(__file__).resolve().parents[2]


async def reset_dut(dut, cycles: int = 4) -> None:
    dut.rst_n.value = 0
    dut.infer_req.value = 0
    dut.spikes_in.value = 0
    for _ in range(cycles):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(cycles):
        await RisingEdge(dut.clk)


async def run_infer(dut, spikes_int: int) -> int:
    dut.spikes_in.value = spikes_int
    dut.infer_req.value = 1
    await RisingEdge(dut.clk)
    dut.infer_req.value = 0

    for _ in range(500_000):
        await RisingEdge(dut.clk)
        if int(dut.done.value) == 1:
            break
    else:
        raise TimeoutError("inference did not complete")

    await RisingEdge(dut.clk)

    value = dut.spikes_out.value
    if hasattr(value, "is_resolvable") and not value.is_resolvable:
        raise ValueError(f"spikes_out unresolved: {value}")
    return int(value)


@cocotb.test()
async def test_mnist_binary_infer(dut):
    """Compare cocotb inference vs chip_model on a few MNIST test images."""
    import yaml
    from torchvision import datasets, transforms

    from host.chip_model import ChipParams, chip_forward
    from host.encoders.image_encoder import ImageEncoder
    from host.mnist_decoder import MnistBinaryDecoder

    cfg_path = REPO_ROOT / "host" / "config_mnist_binary.yaml"
    with cfg_path.open(encoding="utf-8") as f:
        cfg = yaml.safe_load(f)

    weights_path = REPO_ROOT / "host" / "data" / "weights.npy"
    if not weights_path.exists():
        dut._log.warning("weights.npy missing; skipping accuracy check")
        return

    weights = np.load(weights_path).astype(np.int8)
    params = ChipParams.from_config(cfg)
    encoder = ImageEncoder(cfg)
    decoder = MnistBinaryDecoder(cfg)

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    classes = [int(c) for c in cfg["train"]["classes"]]
    root = REPO_ROOT / "host" / "data" / "mnist"
    test_ds = datasets.MNIST(root, train=False, download=True, transform=transforms.ToTensor())
    labels = test_ds.targets.numpy()
    idx = [i for i, y in enumerate(labels) if int(y) in classes][:5]

    matches = 0
    for i in idx:
        img, label = test_ds[i]
        spikes = encoder.encode(img.squeeze(0).numpy())
        packed = sum(int(b) << j for j, b in enumerate(spikes))
        rtl_out = await run_infer(dut, packed)
        rtl_bits = np.array([(rtl_out >> j) & 1 for j in range(40)], dtype=np.uint8)
        py_out = chip_forward(spikes, weights, params)
        if np.array_equal(rtl_bits, py_out):
            matches += 1
        dut._log.info(
            "img=%d label=%d py=%d rtl=%d pred=%d",
            i,
            int(label),
            int(py_out.sum()),
            int(rtl_bits.sum()),
            decoder.decode(rtl_bits),
        )

    dut._log.info("chip_model vs RTL matches: %d/%d", matches, len(idx))
    assert matches >= max(1, len(idx) - 1), "chip_model and RTL outputs diverged on most samples"
