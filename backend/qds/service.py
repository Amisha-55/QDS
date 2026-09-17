import os
import sys
import uuid
import base64
from datetime import datetime, timezone
from typing import Optional, Dict, Any

# Ensure src/ is importable
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from qds_signature import generate_signature
from qds_verify import verify_signature
from classical_signature import sign_data, verify_data
from secure_packet import canonical_json
from replay_attack import check_replay, reset_replay_registry
from backend.qds.key_manager import KeyManager
from backend.qds.models import (
    SecureMessageResult,
    VerificationResult,
    QuantumStats,
    SecurityDecision,
    LikelyAttackType,
)


class QDSService:
    """
    QDS Integration Service Layer.

    Provides a clean, unified application boundary for the FastAPI + WebSocket backend,
    hiding low-level quantum simulation details while orchestrating:
      - Message conversion to Pauli eigenstate teleportation simulations
      - Ed25519 classical signing and verification
      - Canonical JSON payload serialization
      - Replay detection and UUID tracking
      - Statistical quantum accuracy threshold evaluation
    """

    def __init__(
        self,
        key_manager: Optional[KeyManager] = None,
        default_shots: int = 1000,
        default_threshold: float = 0.95,
        default_max_bits: Optional[int] = 8,
    ):
        self.key_manager = key_manager or KeyManager()
        self.default_shots = default_shots
        self.default_threshold = default_threshold
        self.default_max_bits = default_max_bits

    def secure_message(
        self,
        message: str,
        sender_id: str,
        receiver_id: Optional[str] = None,
        private_key: Optional[Any] = None,
        shots: Optional[int] = None,
        max_bits: Optional[int] = None,
    ) -> SecureMessageResult:
        """
        Sender-side integration flow:
          1. Validates input parameters.
          2. Generates QDS-inspired quantum signature via teleportation simulation.
          3. Packages deterministic payload containing message, metadata, and QDS signature.
          4. Signs canonical payload with sender's Ed25519 private key.
          5. Returns structured SecureMessageResult.
        """
        try:
            # 1. Input validation
            if not isinstance(message, str) or not message:
                return SecureMessageResult(
                    success=False,
                    sender_id=sender_id,
                    receiver_id=receiver_id,
                    error="Message must be a non-empty string.",
                )

            if not isinstance(sender_id, str) or not sender_id.strip():
                return SecureMessageResult(
                    success=False,
                    receiver_id=receiver_id,
                    message=message,
                    error="Sender ID must be a non-empty string.",
                )

            sender_id = sender_id.strip()
            shots_val = shots if shots is not None else self.default_shots
            max_bits_val = max_bits if max_bits is not None else self.default_max_bits

            # 2. Resolve private key
            signing_key = private_key
            if signing_key is None:
                signing_key, _ = self.key_manager.get_or_create_key_pair(sender_id)

            # 3. Generate QDS signature
            qds_sig = generate_signature(
                message=message,
                shots=shots_val,
                max_bits=max_bits_val,
            )

            # 4. Construct payload with replay protection metadata
            signature_id = str(uuid.uuid4())
            timestamp = datetime.now(timezone.utc).isoformat()

            payload = {
                "signer_id": sender_id,
                "message": message,
                "signature_id": signature_id,
                "timestamp": timestamp,
                "qds_signature": qds_sig,
            }
            if receiver_id:
                payload["receiver_id"] = receiver_id

            # 5. Canonical Ed25519 signature
            payload_bytes = canonical_json(payload)
            classical_sig_bytes = sign_data(signing_key, payload_bytes)
            encoded_sig = base64.b64encode(classical_sig_bytes).decode("ascii")

            packet = {
                "payload": payload,
                "classical_signature": encoded_sig,
            }

            # 6. Extract quantum telemetry stats
            q_sig_inner = qds_sig.get("quantum_signature", {})
            elements = q_sig_inner.get("elements", [])
            bases_used = list(dict.fromkeys(el.get("basis") for el in elements if "basis" in el))

            stats = QuantumStats(
                bit_count=len(elements),
                overall_accuracy=q_sig_inner.get("overall_accuracy", 1.0),
                shots=shots_val,
                bases_used=bases_used,
            )

            return SecureMessageResult(
                success=True,
                packet=packet,
                signature_id=signature_id,
                timestamp=timestamp,
                sender_id=sender_id,
                receiver_id=receiver_id,
                message=message,
                quantum_stats=stats.to_dict(),
                error=None,
            )

        except Exception as err:
            return SecureMessageResult(
                success=False,
                sender_id=sender_id,
                receiver_id=receiver_id,
                message=message,
                error=f"Failed to secure message: {str(err)}",
            )

    def verify_message(
        self,
        packet: Dict[str, Any],
        public_key: Optional[Any] = None,
        threshold: Optional[float] = None,
    ) -> VerificationResult:
        """
        Receiver-side integration flow:
          1. Validates packet schema and field presence.
          2. Retrieves trusted Ed25519 public key for claimed signer.
          3. Layer 1: Classical Ed25519 verification over canonical JSON payload.
          4. Layer 2: Replay attack detection using signature ID tracking.
          5. Layer 3: QDS projective measurement check and statistical accuracy threshold.
          6. Returns structured VerificationResult with clear diagnostic telemetry.
        """
        threshold_val = threshold if threshold is not None else self.default_threshold

        try:
            # 1. Packet schema validation
            if not isinstance(packet, dict):
                return VerificationResult(
                    success=False,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error="Packet must be a dictionary.",
                )

            if "payload" not in packet or "classical_signature" not in packet:
                return VerificationResult(
                    success=False,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error="Malformed packet: missing 'payload' or 'classical_signature'.",
                )

            payload = packet["payload"]
            if not isinstance(payload, dict):
                return VerificationResult(
                    success=False,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error="Malformed packet: 'payload' must be an object.",
                )

            required_fields = {"signer_id", "message", "qds_signature"}
            if not required_fields.issubset(payload.keys()):
                missing = required_fields - payload.keys()
                return VerificationResult(
                    success=False,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error=f"Malformed payload: missing required fields {missing}.",
                )

            signer_id = payload.get("signer_id")
            receiver_id = payload.get("receiver_id")
            message = payload.get("message")
            signature_id = payload.get("signature_id") or payload.get("qds_signature", {}).get("signature_id")
            timestamp = payload.get("timestamp") or payload.get("qds_signature", {}).get("timestamp")

            # 2. Retrieve trusted public key
            verifying_key = public_key
            if verifying_key is None:
                verifying_key = self.key_manager.get_trusted_public_key(signer_id)

            if verifying_key is None:
                return VerificationResult(
                    success=True,
                    signer_id=signer_id,
                    receiver_id=receiver_id,
                    message=message,
                    signature_id=signature_id,
                    timestamp=timestamp,
                    classical_signature_valid=False,
                    attack_detected=True,
                    likely_attack_type=LikelyAttackType.IMPERSONATION,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error=f"Untrusted or unregistered signer '{signer_id}'. No public key found.",
                )

            # 3. Base64 decode classical signature
            try:
                raw_sig = base64.b64decode(packet["classical_signature"], validate=True)
            except Exception:
                return VerificationResult(
                    success=True,
                    signer_id=signer_id,
                    receiver_id=receiver_id,
                    message=message,
                    signature_id=signature_id,
                    timestamp=timestamp,
                    classical_signature_valid=False,
                    attack_detected=True,
                    likely_attack_type=LikelyAttackType.FORGERY,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error="Corrupted or invalid base64 classical signature.",
                )

            # 4. Layer 1: Ed25519 Classical Verification
            payload_bytes = canonical_json(payload)
            classical_valid = verify_data(verifying_key, payload_bytes, raw_sig)

            if not classical_valid:
                return VerificationResult(
                    success=True,
                    signer_id=signer_id,
                    receiver_id=receiver_id,
                    message=message,
                    signature_id=signature_id,
                    timestamp=timestamp,
                    classical_signature_valid=False,
                    attack_detected=True,
                    likely_attack_type=LikelyAttackType.FORGERY,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error="Classical Ed25519 signature verification failed (payload tampered or mismatched key).",
                )

            # 5. Layer 2: Replay Verification
            replay_detected = False
            if signature_id:
                replay_detected = check_replay(signature_id)

            if replay_detected:
                return VerificationResult(
                    success=True,
                    signer_id=signer_id,
                    receiver_id=receiver_id,
                    message=message,
                    signature_id=signature_id,
                    timestamp=timestamp,
                    classical_signature_valid=True,
                    replay_detected=True,
                    attack_detected=True,
                    likely_attack_type=LikelyAttackType.REPLAY,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    error=f"Replay attack detected: signature_id '{signature_id}' has already been processed.",
                )

            # 6. Layer 3: QDS Quantum Verification
            qds_result = verify_signature(
                signature=payload["qds_signature"],
                message=message,
                threshold=threshold_val,
            )

            qds_valid = (qds_result.get("decision") == "VALID")
            qds_accuracy = qds_result.get("verification_accuracy", 0.0)

            if not qds_valid:
                return VerificationResult(
                    success=True,
                    signer_id=signer_id,
                    receiver_id=receiver_id,
                    message=message,
                    signature_id=signature_id,
                    timestamp=timestamp,
                    classical_signature_valid=True,
                    replay_detected=False,
                    qds_valid=False,
                    qds_accuracy=qds_accuracy,
                    attack_detected=True,
                    likely_attack_type=LikelyAttackType.QUANTUM_TAMPER,
                    final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                    details=qds_result,
                    error="Quantum signature verification failed (statistical accuracy below threshold or hash mismatch).",
                )

            # 7. All checks passed
            return VerificationResult(
                success=True,
                signer_id=signer_id,
                receiver_id=receiver_id,
                message=message,
                signature_id=signature_id,
                timestamp=timestamp,
                classical_signature_valid=True,
                replay_detected=False,
                qds_valid=True,
                qds_accuracy=qds_accuracy,
                attack_detected=False,
                likely_attack_type=LikelyAttackType.LEGITIMATE,
                final_decision=SecurityDecision.TRUSTED,
                details=qds_result,
                error=None,
            )

        except Exception as err:
            return VerificationResult(
                success=False,
                final_decision=SecurityDecision.INVALID_SUSPICIOUS,
                error=f"Verification process encountered an unexpected internal error: {str(err)}",
            )

    def reset_replay_cache(self) -> None:
        """Reset the replay registry cache (useful for testing or demo resets)."""
        reset_replay_registry()
