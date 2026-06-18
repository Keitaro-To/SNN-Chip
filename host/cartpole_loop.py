from __future__ import annotations

import argparse
import sys
from pathlib import Path

import gymnasium as gym
import numpy as np

from host.backends.sim_backend import SimBackend
from host.config import load_config
from host.decoder import ReadoutDecoder
from host.encoder import PopulationEncoder

REPO_ROOT = Path(__file__).resolve().parents[1]


def run_cartpole(
    backend_name: str,
    episodes: int,
    max_steps: int,
    render_mode: str | None,
    log_every: int,
) -> None:
    cfg = load_config()
    encoder = PopulationEncoder(cfg)
    decoder = ReadoutDecoder(cfg)

    if backend_name == "sim":
        backend = SimBackend(REPO_ROOT)
    else:
        from host.backends.uart_backend import UartBackend

        backend = UartBackend(cfg)

    env = gym.make("CartPole-v1", render_mode=render_mode)
    try:
        for ep in range(episodes):
            obs, _ = env.reset(seed=ep)
            total_reward = 0.0
            for step in range(max_steps):
                spikes = encoder.encode(obs)
                out_spikes = backend.infer(spikes)
                action = decoder.decode(out_spikes)
                obs, reward, terminated, truncated, _ = env.step(action)
                total_reward += float(reward)
                if log_every > 0 and step % log_every == 0:
                    print(
                        f"ep={ep} step={step} action={action} "
                        f"reward={reward:.1f} in_pop={int(spikes.sum())} "
                        f"out_pop={int(out_spikes.sum())}"
                    )
                if terminated or truncated:
                    break
            print(f"episode {ep}: steps={step + 1} total_reward={total_reward:.1f}")
    finally:
        env.close()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="CartPole loop with SNN host backend")
    parser.add_argument("--backend", choices=["sim", "uart"], default="sim")
    parser.add_argument("--episodes", type=int, default=1)
    parser.add_argument("--max-steps", type=int, default=500)
    parser.add_argument("--render", action="store_true")
    parser.add_argument("--log-every", type=int, default=50)
    args = parser.parse_args(argv)

    run_cartpole(
        backend_name=args.backend,
        episodes=args.episodes,
        max_steps=args.max_steps,
        render_mode="human" if args.render else None,
        log_every=args.log_every,
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
