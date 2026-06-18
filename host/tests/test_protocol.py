from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from host.protocol import build_infer_request, parse_infer_response, protocol_from_config


def test_infer_frame_roundtrip():
    proto = protocol_from_config()
    spikes = np.zeros(proto.n_exc_inputs, dtype=np.uint8)
    spikes[0] = 1
    spikes[40] = 1
    frame = build_infer_request(spikes, proto)
    assert frame[0] == proto.cmd_infer
    assert len(frame) == 1 + proto.infer_in_bytes

    fake_out = bytearray([proto.status_done])
    for i in range(proto.infer_out_bytes):
        fake_out.append(0)
    fake_out[1] |= 1 << 0
    fake_out[2] |= 1 << 2

    out = parse_infer_response(bytes(fake_out), proto)
    assert out[0] == 1
    assert out[10] == 1


if __name__ == "__main__":
    test_infer_frame_roundtrip()
    print("protocol test OK")
