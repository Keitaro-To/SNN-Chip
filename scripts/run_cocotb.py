#!/usr/bin/env python3
"""Run cocotb tests for network_host_tb (Windows or Linux)."""

from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from cocotb_tools.runner import get_runner


def verilog_sources() -> list[Path]:
    root = REPO_ROOT
    files = [
        root / "rtl/pkg/spiker_pkg.sv",
        root / "rtl/common/add_sub.sv",
        root / "rtl/common/addr_converter.sv",
        root / "rtl/common/and_mask.sv",
        root / "rtl/common/cmp_eq.sv",
        root / "rtl/common/cmp_gt.sv",
        root / "rtl/common/cnt.sv",
        root / "rtl/common/generic_or.sv",
        root / "rtl/common/mux_4to1_signed.sv",
        root / "rtl/common/mux_8to1.sv",
        root / "rtl/common/mux_16to1.sv",
        root / "rtl/common/reg_sync_rst.sv",
        root / "rtl/common/reg_signed_sync_rst.sv",
        root / "rtl/common/shifter.sv",
        root / "rtl/mem/rom_exc.sv",
        root / "rtl/mem/rom_exc_ip.sv",
        root / "rtl/mem/rom_inh.sv",
        root / "rtl/mem/rom_inh_ip.sv",
        root / "rtl/sync/multi_cycle_datapath.sv",
        root / "rtl/sync/multi_cycle_cu.sv",
        root / "rtl/sync/multi_cycle.sv",
        root / "rtl/sync/barrier_cu.sv",
        root / "rtl/sync/barrier.sv",
        root / "rtl/neuron/neuron_cu_subtractive.sv",
        root / "rtl/neuron/neuron_dp_subtractive.sv",
        root / "rtl/neuron/neuron_subtractive.sv",
        root / "rtl/network/multi_input_cu.sv",
        root / "rtl/network/multi_input_dp.sv",
        root / "rtl/network/multi_input.sv",
        root / "rtl/network/layer.sv",
        root / "rtl/top/network.sv",
        root / "rtl/host/network_infer_ctrl.sv",
        root / "tb/system/network_host_tb.sv",
    ]
    return files


def main() -> int:
    sim = os.environ.get("SIM", "icarus")
    test_module = os.environ.get("COCOTB_TEST_MODULE", "test_cartpole_gym")
    if len(sys.argv) > 1 and sys.argv[1] == "--module":
        test_module = sys.argv[2]
        sys.argv = [sys.argv[0], *sys.argv[3:]]
    build_dir = REPO_ROOT / "sim" / "build" / "cocotb"
    build_dir.mkdir(parents=True, exist_ok=True)
    weights_src = REPO_ROOT / "sim" / "mem" / "rom_exc_weights.hex"
    weights_dst = build_dir / "rom_exc_weights.hex"
    if not weights_src.exists():
        raise FileNotFoundError(f"missing ROM weights: {weights_src}")
    shutil.copy(weights_src, weights_dst)
    weights_plusarg = f"+WEIGHTS={weights_dst.as_posix()}"

    runner = get_runner(sim)
    runner.build(
        sources=verilog_sources(),
        hdl_toplevel="network_host_tb",
        always=True,
        build_dir=build_dir,
        waves=True,
        verbose=True,
        timescale=("1ns", "1ps"),
        includes=[str(REPO_ROOT / "rtl" / "pkg")],
        build_args=["-g2012"],
    )
    runner.test(
        hdl_toplevel="network_host_tb",
        test_module=test_module,
        test_dir=str(REPO_ROOT / "sim" / "cocotb"),
        build_dir=build_dir,
        plusargs=["+HOST_SIM", weights_plusarg],
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
