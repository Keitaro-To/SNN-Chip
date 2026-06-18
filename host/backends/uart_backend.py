from __future__ import annotations

import time

import numpy as np
import serial

from host.config import load_config
from host.protocol import build_infer_request, parse_infer_response, protocol_from_config


class UartBackend:
    """Send inference frames to network_uart over serial."""

    def __init__(self, config: dict | None = None) -> None:
        self.cfg = config or load_config()
        self.proto = protocol_from_config(self.cfg)
        uart_cfg = self.cfg["uart"]
        self.port = str(uart_cfg["port"])
        self.baudrate = int(uart_cfg["baudrate"])
        self.timeout = float(uart_cfg["timeout_s"])
        self._ser = serial.Serial(self.port, self.baudrate, timeout=self.timeout)

    def close(self) -> None:
        if self._ser and self._ser.is_open:
            self._ser.close()

    def infer(self, spikes: np.ndarray) -> np.ndarray:
        frame = build_infer_request(spikes, self.proto)
        self._ser.reset_input_buffer()
        self._ser.write(frame)
        self._ser.flush()

        expected = 1 + self.proto.infer_out_bytes
        deadline = time.time() + self.timeout
        buf = bytearray()
        while len(buf) < expected:
            chunk = self._ser.read(expected - len(buf))
            if not chunk:
                if time.time() > deadline:
                    raise TimeoutError("UART infer response timeout")
                continue
            buf.extend(chunk)
        return parse_infer_response(bytes(buf), self.proto)
