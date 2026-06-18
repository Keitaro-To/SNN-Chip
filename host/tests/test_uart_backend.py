from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import numpy as np

REPO_ROOT = Path(__file__).resolve().parents[2]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from host.protocol import build_infer_request, parse_infer_response, protocol_from_config


def test_uart_backend_infer_with_mock_serial():
    from host.backends.uart_backend import UartBackend

    proto = protocol_from_config()
    spikes = np.zeros(proto.n_exc_inputs, dtype=np.uint8)
    spikes[3] = 1
    request = build_infer_request(spikes, proto)

    response_payload = bytearray([proto.status_done])
    for i in range(proto.infer_out_bytes):
        response_payload.append(0)
    response_payload[1] |= 1 << 1

    mock_serial = MagicMock()
    mock_serial.is_open = True
    mock_serial.read.side_effect = [bytes(response_payload)]

    with patch("host.backends.uart_backend.serial.Serial", return_value=mock_serial):
        backend = UartBackend()
        out = backend.infer(spikes)
        backend.close()

    mock_serial.write.assert_called_once()
    assert mock_serial.write.call_args.args[0] == request
    assert out[1] == 1


if __name__ == "__main__":
    test_uart_backend_infer_with_mock_serial()
    print("uart backend mock test OK")
