"""
Automated Integration Tests for QDS Network Gateway

Verifies:
- Server endpoints and health
- Participant registration (X and Y)
- Message transmission and routing through existing QDS research pipeline
- Real security verification results (TRUSTED vs INVALID / SUSPICIOUS)
- Tampering / forgery detection via the gateway
- Replay detection via the gateway
- Receiver offline handling
- Malformed request handling
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

from server.main import app, manager
from server.protocol import (
    TYPE_REGISTER,
    TYPE_REGISTERED,
    TYPE_MESSAGE,
    TYPE_PACKET,
    TYPE_MESSAGE_RESULT,
    TYPE_ACK,
    TYPE_ERROR,
    ERR_UNKNOWN_TYPE,
    ERR_INVALID_FIELD,
    ERR_MISSING_FIELD,
)
from forgery_attack import simulate_forgery
from replay_attack import simulate_replay, reset_replay_registry


@pytest.fixture(autouse=True)
def clean_state():
    """Reset replay registry and session state before each test."""
    reset_replay_registry()
    yield
    reset_replay_registry()


def test_server_metadata_and_health():
    """Verify REST health check and metadata endpoints."""
    with TestClient(app) as client:
        resp_root = client.get("/")
        assert resp_root.status_code == 200
        root_data = resp_root.json()
        assert root_data["service"] == "QDS Network Gateway"
        assert root_data["status"] == "online"

        resp_health = client.get("/health")
        assert resp_health.status_code == 200
        assert resp_health.json()["status"] == "healthy"


def test_registration_flow():
    """Verify registration for X (sender) and Y (receiver)."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws:
            ws.send_json({
                "type": TYPE_REGISTER,
                "user_id": "X",
                "role": "sender",
            })
            res = ws.receive_json()
            assert res["type"] == TYPE_REGISTERED
            assert res["user_id"] == "X"
            assert res["role"] == "sender"
            assert res["status"] == "success"


def test_end_to_end_message_routing_and_qds_verification():
    """
    Verify complete flow:
    Flutter X connects -> sends message -> QDS core generates & verifies packet
    -> Gateway routes real result to Flutter Y -> X receives delivery ack.
    """
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            # 1. Register X
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            res_x_reg = ws_x.receive_json()
            assert res_x_reg["type"] == TYPE_REGISTERED

            # 2. Register Y
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            res_y_reg = ws_y.receive_json()
            assert res_y_reg["type"] == TYPE_REGISTERED

            # 3. X sends message to Y
            test_msg = "QDS-Quantum-Verification-Live-Test"
            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y",
                "message": test_msg,
            })

            # 4. Y receives the verified message envelope
            msg_for_y = ws_y.receive_json()
            assert msg_for_y["type"] == TYPE_MESSAGE_RESULT
            assert msg_for_y["sender_id"] == "X"
            assert msg_for_y["receiver_id"] == "Y"
            assert msg_for_y["message"] == test_msg

            # Verify REAL security outputs from research core
            sec = msg_for_y["security"]
            assert sec["final_decision"] == "TRUSTED"
            assert sec["likely_attack_type"] == "LEGITIMATE"
            assert sec["classical_signature_valid"] is True
            assert sec["qds_valid"] is True
            assert sec["replay_detected"] is False
            assert sec["verification_accuracy"] >= 0.90
            assert sec["quantum_bit_count"] > 0
            assert sec["total_shots"] > 0

            # 5. X receives delivery acknowledgment
            ack_for_x = ws_x.receive_json()
            assert ack_for_x["type"] == TYPE_ACK
            assert ack_for_x["status"] == "delivered"
            assert ack_for_x["details"]["receiver_connected"] is True
            assert ack_for_x["details"]["final_decision"] == "TRUSTED"


def test_receiver_offline_handling():
    """Verify acknowledgment indicates offline status when receiver is not connected."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()

            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y_OFFLINE",
                "message": "Hello offline user",
            })

            ack = ws_x.receive_json()
            assert ack["type"] == TYPE_ACK
            assert ack["status"] == "receiver_offline"
            assert ack["details"]["receiver_connected"] is False
            assert ack["details"]["final_decision"] == "TRUSTED"


def test_tamper_forgery_detection():
    """
    Verify that an attacked/forged packet sent to the gateway is caught
    by the existing security pipeline and produces an INVALID / SUSPICIOUS result.
    """
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # First send a valid message to obtain a real legitimate packet
            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y",
                "message": "Original Message",
            })
            valid_envelope = ws_y.receive_json()
            _ = ws_x.receive_json()  # ack

            legit_packet = valid_envelope["packet"]

            # Simulate attack: tamper message text without re-signing
            tampered_packet = simulate_forgery(legit_packet, forged_message="Tampered Message")

            # Reset replay registry so the test isolates forgery from replay
            reset_replay_registry()

            # Send the forged packet through the gateway
            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": tampered_packet,
            })

            # Y should receive an envelope flagged as INVALID / SUSPICIOUS
            y_received = ws_y.receive_json()
            assert y_received["type"] == TYPE_MESSAGE_RESULT
            assert y_received["security"]["final_decision"] == "INVALID / SUSPICIOUS"
            assert y_received["security"]["classical_signature_valid"] is False
            assert y_received["security"]["likely_attack_type"] == "FORGERY_OR_IMPERSONATION"


def test_replay_attack_detection():
    """
    Verify that re-sending an already accepted packet is caught
    by check_replay in the security pipeline.
    """
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # Send first message
            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y",
                "message": "Replay Candidate",
            })
            first_envelope = ws_y.receive_json()
            _ = ws_x.receive_json()
            assert first_envelope["security"]["final_decision"] == "TRUSTED"

            # Replay the identical packet
            replayed_packet = simulate_replay(first_envelope["packet"])
            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": replayed_packet,
            })

            replayed_result = ws_y.receive_json()
            assert replayed_result["type"] == TYPE_MESSAGE_RESULT
            assert replayed_result["security"]["replay_detected"] is True
            assert replayed_result["security"]["final_decision"] == "INVALID / SUSPICIOUS"
            assert replayed_result["security"]["likely_attack_type"] == "REPLAY"


def test_malformed_and_error_handling():
    """Verify clean error responses for malformed payloads and invalid inputs."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws:
            # 1. Missing type
            ws.send_json({"foo": "bar"})
            err1 = ws.receive_json()
            assert err1["type"] == TYPE_ERROR
            assert err1["error_code"] == ERR_MISSING_FIELD

            # 2. Unknown type
            ws.send_json({"type": "nonexistent_action"})
            err2 = ws.receive_json()
            assert err2["type"] == TYPE_ERROR
            assert err2["error_code"] == ERR_UNKNOWN_TYPE

            # 3. Invalid role
            ws.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "attacker"})
            err3 = ws.receive_json()
            assert err3["type"] == TYPE_ERROR
            assert err3["error_code"] == ERR_INVALID_FIELD
