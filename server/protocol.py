"""
QDS Network Gateway Protocol Specification

Defines message types, payload contracts, and serialization helpers
for communication between Flutter clients and the Python QDS Gateway.
"""

from datetime import datetime, timezone
from typing import Any, Dict, Optional


# Protocol Message Types
TYPE_REGISTER = "register"
TYPE_REGISTERED = "registered"
TYPE_MESSAGE = "message"
TYPE_PACKET = "packet"
TYPE_MESSAGE_RESULT = "message_result"
TYPE_ACK = "ack"
TYPE_ERROR = "error"

# Protocol Roles
ROLE_SENDER = "sender"
ROLE_RECEIVER = "receiver"
VALID_ROLES = {ROLE_SENDER, ROLE_RECEIVER}

# Error Codes
ERR_INVALID_JSON = "invalid_json"
ERR_MISSING_FIELD = "missing_field"
ERR_INVALID_FIELD = "invalid_field"
ERR_UNKNOWN_TYPE = "unknown_type"
ERR_NOT_REGISTERED = "not_registered"
ERR_RECEIVER_OFFLINE = "receiver_offline"
ERR_PROCESSING_FAILED = "processing_failed"


def now_utc_iso() -> str:
    """Return the current UTC timestamp formatted as ISO 8601 string."""
    return datetime.now(timezone.utc).isoformat()


def create_error_message(code: str, message: str, details: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Create a structured error message payload."""
    payload: Dict[str, Any] = {
        "type": TYPE_ERROR,
        "error_code": code,
        "message": message,
        "timestamp": now_utc_iso(),
    }
    if details:
        payload["details"] = details
    return payload


def create_registered_message(user_id: str, role: str) -> Dict[str, Any]:
    """Create a registration confirmation payload."""
    return {
        "type": TYPE_REGISTERED,
        "user_id": user_id,
        "role": role,
        "status": "success",
        "timestamp": now_utc_iso(),
    }


def create_ack_message(
    message_id: str,
    status: str = "delivered",
    details: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Create an acknowledgment payload sent back to the sender."""
    payload: Dict[str, Any] = {
        "type": TYPE_ACK,
        "message_id": message_id,
        "status": status,
        "timestamp": now_utc_iso(),
    }
    if details:
        payload["details"] = details
    return payload


def format_security_summary(verification_result: Dict[str, Any], attack_type: str) -> Dict[str, Any]:
    """
    Format security telemetry strictly using the outputs returned by the
    existing Python research pipeline (secure_packet.py, security_pipeline.py).

    No fake or invented fields are added.
    """
    qds_result = verification_result.get("qds_result", {})
    verification_accuracy = float(qds_result.get("verification_accuracy", 0.0))
    error_rate = round(1.0 - verification_accuracy, 4)

    return {
        "final_decision": verification_result.get("final_decision", "INVALID / SUSPICIOUS"),
        "likely_attack_type": attack_type,
        "classical_signature_valid": bool(verification_result.get("classical_signature_valid", False)),
        "qds_valid": qds_result.get("decision") == "VALID",
        "replay_detected": bool(verification_result.get("replay_detected", False)),
        "verification_accuracy": round(verification_accuracy, 4),
        "error_rate": error_rate,
        "quantum_bit_count": int(qds_result.get("quantum_bit_count", 0)),
        "total_shots": int(qds_result.get("total_shots", 0)),
        "correct_shots": int(qds_result.get("correct_shots", 0)),
        "threshold": float(qds_result.get("threshold", 0.95)),
        "qds_decision": str(qds_result.get("decision", "NOT VERIFIED")),
        "signer_id": verification_result.get("signer_id"),
    }


def create_message_result_envelope(
    sender_id: str,
    receiver_id: str,
    message: str,
    packet: Dict[str, Any],
    verification_result: Dict[str, Any],
    attack_type: str,
) -> Dict[str, Any]:
    """
    Construct the full network envelope for a verified (or flagged) message.
    Preserves raw packet and actual cryptographic verification outputs.
    """
    message_id = (
        packet.get("payload", {}).get("signature_id")
        or packet.get("payload", {}).get("qds_signature", {}).get("signature_id")
        or ""
    )
    timestamp = (
        packet.get("payload", {}).get("timestamp")
        or packet.get("payload", {}).get("qds_signature", {}).get("timestamp")
        or now_utc_iso()
    )

    security_summary = format_security_summary(verification_result, attack_type)

    return {
        "type": TYPE_MESSAGE_RESULT,
        "message_id": message_id,
        "sender_id": sender_id,
        "receiver_id": receiver_id,
        "message": message,
        "packet": packet,
        "security": security_summary,
        "timestamp": timestamp,
    }
