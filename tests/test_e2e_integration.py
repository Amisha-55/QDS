"""
End-to-End Live Integration Tests for QDS Network Gateway & Multi-Client Flow

Verifies:
1. Two-client simultaneous connection (X = sender, Y = receiver).
2. Normal message flow (X -> Gateway -> QDS Core -> Y + X ACK).
3. Reverse message flow (Y -> Gateway -> QDS Core -> X + Y ACK).
4. Burst message ordering and deduplication (FIFO sequence).
5. Live attack flows through the gateway:
   - Forgery Attack
   - Impersonation Attack
   - Replay Attack (with replay detector triggering)
   - Channel Manipulation Attack (quantum degradation)
6. Session takeover and client reconnection handling.
"""

import os
import sys
import pytest
from fastapi.testclient import TestClient

ROOT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_PATH = os.path.join(ROOT_PATH, "src")
for p in [ROOT_PATH, SRC_PATH]:
    if p not in sys.path:
        sys.path.insert(0, p)

from server.main import app, manager
from server.handlers import ensure_user_keys
from server.protocol import (
    TYPE_REGISTER,
    TYPE_REGISTERED,
    TYPE_MESSAGE,
    TYPE_PACKET,
    TYPE_MESSAGE_RESULT,
    TYPE_ACK,
)
from replay_attack import build_replay_packet, reset_replay_registry
from attack_console.attacks.forgery import prepare_forgery_packet
from attack_console.attacks.impersonation import prepare_impersonation_packet
from attack_console.attacks.replay import prepare_replay_packet
from attack_console.attacks.channel_manipulation import prepare_channel_manipulated_packet


@pytest.fixture(autouse=True)
def reset_state():
    """Reset replay registry before and after every test."""
    reset_replay_registry()
    yield
    reset_replay_registry()


def test_two_clients_simultaneous_connection():
    """Verify X and Y can connect and register simultaneously."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            # Register X
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            reg_x = ws_x.receive_json()
            assert reg_x["type"] == TYPE_REGISTERED
            assert reg_x["user_id"] == "X"
            assert reg_x["role"] == "sender"

            # Register Y
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            reg_y = ws_y.receive_json()
            assert reg_y["type"] == TYPE_REGISTERED
            assert reg_y["user_id"] == "Y"
            assert reg_y["role"] == "receiver"

            # Check server session list
            assert manager.is_connected("X")
            assert manager.is_connected("Y")
            sessions = manager.get_active_sessions()
            assert "X" in sessions
            assert "Y" in sessions


def test_end_to_end_normal_message_x_to_y():
    """Verify X -> Gateway -> Research Core -> Y with ACK."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # X sends message
            message_text = "Hello Y, this is a quantum-verified transmission."
            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y",
                "message": message_text,
            })

            # Y receives verified envelope
            y_envelope = ws_y.receive_json()
            assert y_envelope["type"] == TYPE_MESSAGE_RESULT
            assert y_envelope["sender_id"] == "X"
            assert y_envelope["receiver_id"] == "Y"
            assert y_envelope["message"] == message_text
            assert y_envelope["security"]["final_decision"] == "TRUSTED"
            assert y_envelope["security"]["likely_attack_type"] == "LEGITIMATE"
            assert y_envelope["security"]["classical_signature_valid"] is True
            assert y_envelope["security"]["qds_valid"] is True
            assert y_envelope["security"]["replay_detected"] is False

            # X receives ACK
            x_ack = ws_x.receive_json()
            assert x_ack["type"] == TYPE_ACK
            assert x_ack["status"] == "delivered"
            assert x_ack["message_id"] == y_envelope["message_id"]
            assert x_ack["details"]["receiver_connected"] is True
            assert x_ack["details"]["final_decision"] == "TRUSTED"


def test_end_to_end_reverse_message_y_to_x():
    """Verify Y -> Gateway -> Research Core -> X with ACK (role-independent)."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # Y sends message to X
            message_text = "Acknowledged X, reverse transmission received."
            ws_y.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "Y",
                "receiver_id": "X",
                "message": message_text,
            })

            # X receives envelope
            x_envelope = ws_x.receive_json()
            assert x_envelope["type"] == TYPE_MESSAGE_RESULT
            assert x_envelope["sender_id"] == "Y"
            assert x_envelope["receiver_id"] == "X"
            assert x_envelope["message"] == message_text
            assert x_envelope["security"]["final_decision"] == "TRUSTED"
            assert x_envelope["security"]["likely_attack_type"] == "LEGITIMATE"
            assert x_envelope["security"]["classical_signature_valid"] is True
            assert x_envelope["security"]["qds_valid"] is True

            # Y receives ACK
            y_ack = ws_y.receive_json()
            assert y_ack["type"] == TYPE_ACK
            assert y_ack["status"] == "delivered"
            assert y_ack["message_id"] == x_envelope["message_id"]


def test_end_to_end_burst_message_ordering():
    """Verify rapid consecutive messages arrive in exact sequence without duplication."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            messages = [f"Burst Message #{i}" for i in range(1, 4)]
            for m in messages:
                ws_x.send_json({
                    "type": TYPE_MESSAGE,
                    "sender_id": "X",
                    "receiver_id": "Y",
                    "message": m,
                })

            # Collect envelopes on Y and ACKs on X
            received_messages = []
            for _ in range(3):
                env = ws_y.receive_json()
                received_messages.append(env["message"])
                ack = ws_x.receive_json()
                assert ack["status"] == "delivered"

            assert received_messages == messages


def test_end_to_end_forgery_attack():
    """Verify attack packet with modified payload is flagged as FORGERY_OR_IMPERSONATION."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # Generate base legitimate packet
            priv_key, _ = ensure_user_keys("X")
            legit_packet = build_replay_packet("Genuine message", priv_key, "X")

            # Tamper with payload (forgery)
            forged_packet = prepare_forgery_packet(legit_packet, "Tampered payload by attacker")
            reset_replay_registry()

            # Attacker/Console injects raw packet to Y
            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": forged_packet,
            })

            # Y receives envelope with threat classification
            y_env = ws_y.receive_json()
            assert y_env["security"]["final_decision"] == "INVALID / SUSPICIOUS"
            assert y_env["security"]["likely_attack_type"] == "FORGERY_OR_IMPERSONATION"
            assert y_env["security"]["classical_signature_valid"] is False


def test_end_to_end_impersonation_attack():
    """Verify packet forged under unauthorized identity is flagged as FORGERY_OR_IMPERSONATION."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # Attacker signs a packet claiming to be X
            impersonated = prepare_impersonation_packet("Eve's fake data", claimed_signer_id="X")
            reset_replay_registry()

            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": impersonated,
            })

            y_env = ws_y.receive_json()
            assert y_env["security"]["final_decision"] == "INVALID / SUSPICIOUS"
            assert y_env["security"]["likely_attack_type"] == "FORGERY_OR_IMPERSONATION"
            assert y_env["security"]["classical_signature_valid"] is False


def test_end_to_end_replay_attack():
    """Verify replayed packet triggers replay detector."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            # 1. Send legitimate message
            ws_x.send_json({
                "type": TYPE_MESSAGE,
                "sender_id": "X",
                "receiver_id": "Y",
                "message": "Original One-Time Token",
            })
            first_env = ws_y.receive_json()
            _ = ws_x.receive_json()  # ACK
            assert first_env["security"]["replay_detected"] is False
            assert first_env["security"]["final_decision"] == "TRUSTED"

            # 2. Replay the exact packet
            replayed_packet = prepare_replay_packet(first_env["packet"])
            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": replayed_packet,
            })

            # 3. Y receives replay alert
            replay_env = ws_y.receive_json()
            assert replay_env["security"]["replay_detected"] is True
            assert replay_env["security"]["likely_attack_type"] == "REPLAY"
            assert replay_env["security"]["final_decision"] == "INVALID / SUSPICIOUS"


def test_end_to_end_channel_manipulation_attack():
    """Verify quantum state manipulation degrades QDS fidelity while classical signature is intact."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws_x, client.websocket_connect("/ws") as ws_y:
            ws_x.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws_x.receive_json()
            ws_y.send_json({"type": TYPE_REGISTER, "user_id": "Y", "role": "receiver"})
            _ = ws_y.receive_json()

            priv_key, _ = ensure_user_keys("X")
            legit_packet = build_replay_packet("Quantum test", priv_key, "X")

            # Degrade quantum states using bit flip
            manipulated = prepare_channel_manipulated_packet(legit_packet, priv_key, attack_type="bit_flip")
            reset_replay_registry()

            ws_x.send_json({
                "type": TYPE_PACKET,
                "sender_id": "X",
                "receiver_id": "Y",
                "packet": manipulated,
            })

            y_env = ws_y.receive_json()
            # Quantum signature failed
            assert y_env["security"]["qds_valid"] is False
            assert y_env["security"]["likely_attack_type"] == "CHANNEL_ATTACK"
            assert y_env["security"]["final_decision"] == "INVALID / SUSPICIOUS"
            # Classical signature remained untouched
            assert y_env["security"]["classical_signature_valid"] is True


def test_client_reconnection_and_session_cleanup():
    """Verify re-registering on a new socket cleans up the previous connection cleanly."""
    with TestClient(app) as client:
        with client.websocket_connect("/ws") as ws1:
            ws1.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
            _ = ws1.receive_json()
            assert manager.is_connected("X")

            # Second connection takes over identity
            with client.websocket_connect("/ws") as ws2:
                ws2.send_json({"type": TYPE_REGISTER, "user_id": "X", "role": "sender"})
                res2 = ws2.receive_json()
                assert res2["status"] == "success"
                assert manager.is_connected("X")
