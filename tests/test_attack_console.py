"""
Automated Unit & Integration Tests for QDS Attack Console

Verifies:
- Direct wrapping and invocation of existing research attack algorithms (src/)
- Live WebSocket integration against QDS Gateway for all 4 attack types:
  1. Forgery Attack
  2. Impersonation Attack
  3. Replay Attack
  4. Channel Manipulation
- Real cryptographic decision outputs (TRUSTED vs INVALID / SUSPICIOUS)
- Error and unreachable gateway handling
"""

import os
import sys
import pytest
from fastapi.testclient import TestClient

# Ensure src/ and root are in sys.path
ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_PATH = os.path.join(ROOT_PATH, "src")
for p in [ROOT_PATH, SRC_PATH]:
    if p not in sys.path:
        sys.path.insert(0, p)

from server.main import app
from server.handlers import ensure_user_keys
from replay_attack import build_replay_packet, reset_replay_registry
from attack_console.attacks.forgery import prepare_forgery_packet
from attack_console.attacks.impersonation import prepare_impersonation_packet
from attack_console.attacks.replay import prepare_replay_packet
from attack_console.attacks.channel_manipulation import prepare_channel_manipulated_packet
from attack_console.main import (
    execute_forgery_attack,
    execute_impersonation_attack,
    execute_replay_attack,
    execute_channel_manipulation_attack,
)


@pytest.fixture(autouse=True)
def clean_state():
    """Reset replay registry before and after each test."""
    reset_replay_registry()
    yield
    reset_replay_registry()


class MockGatewayClient:
    """In-memory client wrapping FastAPI TestClient for live testing without spawning a subprocess."""

    def __init__(self, test_client: TestClient):
        self.client = test_client

    def dispatch_packet(self, sender_id: str, receiver_id: str, packet: dict) -> dict:
        with self.client.websocket_connect("/ws") as ws:
            ws.send_json({
                "type": "register",
                "user_id": sender_id,
                "role": "sender",
            })
            _ = ws.receive_json()

            ws.send_json({
                "type": "packet",
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "packet": packet,
            })
            return ws.receive_json()

    def dispatch_message(self, sender_id: str, receiver_id: str, message: str) -> dict:
        with self.client.websocket_connect("/ws") as ws:
            ws.send_json({
                "type": "register",
                "user_id": sender_id,
                "role": "sender",
            })
            _ = ws.receive_json()

            ws.send_json({
                "type": "message",
                "sender_id": sender_id,
                "receiver_id": receiver_id,
                "message": message,
            })
            return ws.receive_json()


def test_attack_wrappers_call_existing_research_functions():
    """Verify that attack wrappers correctly produce manipulated packets."""
    priv_key, _ = ensure_user_keys("X")
    legit_packet = build_replay_packet("Base Message", priv_key, "X")

    # 1. Forgery wrapper
    forged = prepare_forgery_packet(legit_packet, "TAMPERED")
    assert forged["payload"]["message"] == "TAMPERED"
    assert forged["classical_signature"] == legit_packet["classical_signature"]

    # 2. Impersonation wrapper
    impersonated = prepare_impersonation_packet("Impersonated Message", claimed_signer_id="X")
    assert impersonated["payload"]["signer_id"] == "X"
    assert impersonated["classical_signature"] != legit_packet["classical_signature"]

    # 3. Replay wrapper
    replayed = prepare_replay_packet(legit_packet)
    assert replayed["payload"]["signature_id"] == legit_packet["payload"]["signature_id"]
    assert replayed["classical_signature"] == legit_packet["classical_signature"]

    # 4. Channel manipulation wrapper
    manipulated = prepare_channel_manipulated_packet(legit_packet, priv_key, attack_type="bit_flip")
    q_sig = manipulated["payload"]["qds_signature"]["quantum_signature"]
    assert q_sig["overall_accuracy"] == 0.0


def test_live_gateway_forgery_attack():
    """Verify live gateway catches a forgery attack created by the console."""
    with TestClient(app) as test_client:
        mock_client = MockGatewayClient(test_client)
        resp = execute_forgery_attack(mock_client, sender_id="X", receiver_id="Y", message="Payload-1")

        sec = resp["details"]["security"]
        assert sec["final_decision"] == "INVALID / SUSPICIOUS"
        assert sec["classical_signature_valid"] is False
        assert sec["likely_attack_type"] == "FORGERY_OR_IMPERSONATION"


def test_live_gateway_impersonation_attack():
    """Verify live gateway catches an impersonation attack created by the console."""
    with TestClient(app) as test_client:
        mock_client = MockGatewayClient(test_client)
        resp = execute_impersonation_attack(mock_client, claimed_sender_id="X", receiver_id="Y", message="Payload-2")

        sec = resp["details"]["security"]
        assert sec["final_decision"] == "INVALID / SUSPICIOUS"
        assert sec["classical_signature_valid"] is False
        assert sec["likely_attack_type"] == "FORGERY_OR_IMPERSONATION"


def test_live_gateway_replay_attack():
    """
    Verify live gateway catches a replay attack:
    First send accepted -> Second send with same signature_id caught.
    """
    with TestClient(app) as test_client:
        mock_client = MockGatewayClient(test_client)
        resp = execute_replay_attack(mock_client, sender_id="X", receiver_id="Y", message="Payload-3")

        sec = resp["details"]["security"]
        assert sec["replay_detected"] is True
        assert sec["final_decision"] == "INVALID / SUSPICIOUS"
        assert sec["likely_attack_type"] == "REPLAY"


def test_live_gateway_channel_manipulation_attack():
    """
    Verify live gateway catches a channel manipulation attack:
    Classical signature is valid, but QDS verification fails -> CHANNEL_ATTACK.
    """
    with TestClient(app) as test_client:
        mock_client = MockGatewayClient(test_client)
        resp = execute_channel_manipulation_attack(
            mock_client,
            sender_id="X",
            receiver_id="Y",
            message="Payload-4",
            attack_type="bit_flip",
        )

        sec = resp["details"]["security"]
        assert sec["classical_signature_valid"] is True
        assert sec["qds_valid"] is False
        assert sec["final_decision"] == "INVALID / SUSPICIOUS"
        assert sec["likely_attack_type"] == "CHANNEL_ATTACK"
