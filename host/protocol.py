from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from host.config import load_config, pack_bits_lsb_first, unpack_bits_lsb_first


@dataclass
class ProtocolConfig:
    cmd_infer: int
    status_done: int
    infer_in_bytes: int
    infer_out_bytes: int
    n_exc_inputs: int
    n_neurons: int


def protocol_from_config(config: dict | None = None) -> ProtocolConfig:
    cfg = config or load_config()
    proto = cfg["protocol"]
    return ProtocolConfig(
        cmd_infer=int(proto["cmd_infer"]),
        status_done=int(proto["status_done"]),
        infer_in_bytes=int(proto["infer_in_bytes"]),
        infer_out_bytes=int(proto["infer_out_bytes"]),
        n_exc_inputs=int(cfg["n_exc_inputs"]),
        n_neurons=int(cfg["n_neurons"]),
    )


def build_infer_request(spikes: np.ndarray, proto: ProtocolConfig | None = None) -> bytes:
    proto = proto or protocol_from_config()
    payload = pack_bits_lsb_first(spikes, proto.infer_in_bytes)
    return bytes([proto.cmd_infer]) + payload


def parse_infer_response(frame: bytes, proto: ProtocolConfig | None = None) -> np.ndarray:
    proto = proto or protocol_from_config()
    expected = 1 + proto.infer_out_bytes
    if len(frame) < expected:
        raise ValueError(f"short infer response: {len(frame)} < {expected}")
    if frame[0] != proto.status_done:
        raise ValueError(f"unexpected status byte 0x{frame[0]:02x}")
    payload = frame[1 : 1 + proto.infer_out_bytes]
    return unpack_bits_lsb_first(payload, proto.n_neurons)
