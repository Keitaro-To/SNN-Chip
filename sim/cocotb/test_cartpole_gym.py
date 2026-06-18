import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

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
    return int(dut.spikes_out.value)


@cocotb.test()
async def test_single_infer(dut):
    """Smoke test: one inference request returns output spikes."""
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await reset_dut(dut)
    out = await run_infer(dut, 1)
    dut._log.info("out_spikes=0x%x", out)
    assert out >= 0


@cocotb.test()
async def test_cartpole_gym_loop(dut):
    """Run a short CartPole episode through encoder -> DUT -> decoder."""
    import gymnasium as gym
    import numpy as np

    from host.decoder import ReadoutDecoder
    from host.encoder import PopulationEncoder

    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())
    await reset_dut(dut)

    encoder = PopulationEncoder()
    decoder = ReadoutDecoder()
    env = gym.make("CartPole-v1")
    obs, _ = env.reset(seed=0)
    max_steps = 20

    try:
        for step in range(max_steps):
            spikes = encoder.encode(obs)
            packed = 0
            for i, bit in enumerate(spikes):
                if bit:
                    packed |= 1 << i
            out_val = await run_infer(dut, packed)
            out_bits = np.array([(out_val >> i) & 1 for i in range(40)], dtype=np.uint8)
            action = decoder.decode(out_bits)
            obs, reward, terminated, truncated, _ = env.step(action)
            dut._log.info("step=%d action=%d reward=%.1f", step, action, reward)
            if terminated or truncated:
                break
        dut._log.info("episode finished at step=%d", step)
    finally:
        env.close()
