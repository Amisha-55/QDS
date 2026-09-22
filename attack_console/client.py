"""
Gateway Client for Attack Console

Communicates with the running QDS Gateway WebSocket endpoint (`ws://<host>:8000/ws`)
to dispatch legitimate, manipulated, and attack packets, and retrieves real security outputs.
"""

import json
import logging
from typing import Any, Dict, Optional
from websockets.sync.client import connect

logger = logging.getLogger("qds_attack_console.client")


class GatewayClient:
    """Client for sending attack payloads to the QDS Gateway."""

    def __init__(self, ws_url: str = "ws://127.0.0.1:8000/ws") -> None:
        self.ws_url = ws_url

    def dispatch_packet(
        self,
        sender_id: str,
        receiver_id: str,
        packet: Dict[str, Any],
        timeout: float = 10.0,
    ) -> Dict[str, Any]:
        """
        Connect to the gateway, register the sender, dispatch the raw packet,
        and wait for the gateway's real cryptographic acknowledgment.
        """
        logger.info("Connecting to gateway at %s", self.ws_url)

        with connect(self.ws_url, close_timeout=timeout) as ws:
            # 1. Register session
            ws.send(json.dumps({
                "type": "register",
                "user_id": sender_id,
                "role": "sender",
            }))
            reg_response = json.loads(ws.recv())
            if reg_response.get("type") == "error":
                raise RuntimeError(f"Registration failed: {reg_response.get('message')}")

            # 2. Dispatch packet
            payload = {
                "type": "packet",
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "packet": packet,
            }
            ws.send(json.dumps(payload))

            # 3. Await acknowledgment containing the real security verification details
            raw_response = ws.recv()
            ack_response = json.loads(raw_response)
            return ack_response

    def dispatch_message(
        self,
        sender_id: str,
        receiver_id: str,
        message: str,
        timeout: float = 10.0,
    ) -> Dict[str, Any]:
        """
        Send a standard plaintext message through the gateway to trigger legitimate
        QDS processing and obtain the baseline legitimate packet and security result.
        """
        with connect(self.ws_url, close_timeout=timeout) as ws:
            ws.send(json.dumps({
                "type": "register",
                "user_id": sender_id,
                "role": "sender",
            }))
            _ = json.loads(ws.recv())

            ws.send(json.dumps({
                "type": "message",
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "message": message,
            }))

            ack_response = json.loads(ws.recv())
            return ack_response
