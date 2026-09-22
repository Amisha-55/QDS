"""
QDS Gateway Message & Security Handlers

Directly interfaces with the existing research core (src/) to perform:
- Key pair retrieval/registration
- Quantum signature generation & Ed25519 packet construction
- Multi-layer packet verification (Classical + QDS + Replay)
- Attack classification
"""

import os
import sys
import logging
from typing import Any, Dict, Tuple

# Ensure existing research modules in src/ can be imported without modifying them
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from classical_signature import (
    generate_key_pair,
    save_private_key,
    load_private_key,
)
from trusted_keys import (
    register_public_key,
    get_public_key,
    user_exists,
)
from security_pipeline import (
    verify_packet,
    classify_attack,
    DEFAULT_THRESHOLD,
)
from replay_attack import build_replay_packet
from server.protocol import create_message_result_envelope

logger = logging.getLogger("qds_gateway.handlers")

KEYS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "keys"))


def ensure_user_keys(user_id: str) -> Tuple[Any, Any]:
    """
    Ensure an Ed25519 key pair exists for user_id and is registered in the trusted registry.
    Uses classical_signature.py and trusted_keys.py directly.
    """
    os.makedirs(KEYS_DIR, exist_ok=True)
    priv_file = os.path.join(KEYS_DIR, f"{user_id}_private.pem")

    if os.path.exists(priv_file):
        try:
            private_key = load_private_key(priv_file)
            public_key = private_key.public_key()
            if not user_exists(user_id):
                register_public_key(user_id, public_key)
            return private_key, public_key
        except Exception as exc:
            logger.warning("Error loading existing key for %s (%s). Regenerating.", user_id, exc)

    private_key, public_key = generate_key_pair()
    save_private_key(private_key, priv_file)
    try:
        register_public_key(user_id, public_key)
    except ValueError as exc:
        # If already registered with same/different key in public_keys.json
        logger.info("Registry notice for %s: %s", user_id, exc)

    return private_key, public_key


def process_message(
    sender_id: str,
    receiver_id: str,
    message: str,
    threshold: float = DEFAULT_THRESHOLD,
) -> Dict[str, Any]:
    """
    Process an outgoing message through the full existing research pipeline:
    1. Signer credentials lookup
    2. build_replay_packet (qds_signature.generate_signature + canonical_json + classical_signature.sign_data)
    3. verify_packet (Ed25519 + qds_verify.verify_signature + check_replay)
    4. classify_attack
    5. Envelope construction with real research outputs
    """
    logger.info("Processing message from '%s' to '%s'", sender_id, receiver_id)

    # 1. Signer credentials
    private_key, _ = ensure_user_keys(sender_id)

    # 2. Packet generation via research pipeline
    packet = build_replay_packet(
        message=message,
        private_key=private_key,
        signer_id=sender_id,
    )

    # 3. Verification via research pipeline
    trusted_pub_key = get_public_key(sender_id)
    verification_result = verify_packet(packet, trusted_pub_key, threshold=threshold)

    # 4. Attack classification
    attack_type = classify_attack(verification_result)

    # 5. Envelope
    envelope = create_message_result_envelope(
        sender_id=sender_id,
        receiver_id=receiver_id,
        message=message,
        packet=packet,
        verification_result=verification_result,
        attack_type=attack_type,
    )

    logger.info(
        "Security decision for message from '%s': decision='%s', attack_type='%s', accuracy=%.4f",
        sender_id,
        envelope["security"]["final_decision"],
        envelope["security"]["likely_attack_type"],
        envelope["security"]["verification_accuracy"],
    )

    return envelope


def process_raw_packet(
    sender_id: str,
    receiver_id: str,
    packet: Dict[str, Any],
    threshold: float = DEFAULT_THRESHOLD,
) -> Dict[str, Any]:
    """
    Process a pre-formed or attack-modified packet through the research verification pipeline.
    Preserves raw findings without altering the packet.
    """
    logger.info("Processing raw packet from '%s' to '%s'", sender_id, receiver_id)

    claimed_signer = packet.get("payload", {}).get("signer_id", sender_id)
    message_content = packet.get("payload", {}).get("message", "")

    # Retrieve trusted public key for the claimed signer
    if user_exists(claimed_signer):
        trusted_pub_key = get_public_key(claimed_signer)
    else:
        # Fallback to sender_id if claimed signer not in registry
        _, trusted_pub_key = ensure_user_keys(claimed_signer)

    # Verify through research pipeline
    verification_result = verify_packet(packet, trusted_pub_key, threshold=threshold)
    attack_type = classify_attack(verification_result)

    envelope = create_message_result_envelope(
        sender_id=sender_id,
        receiver_id=receiver_id,
        message=message_content,
        packet=packet,
        verification_result=verification_result,
        attack_type=attack_type,
    )

    logger.info(
        "Raw packet security decision: decision='%s', attack_type='%s', classical_valid=%s",
        envelope["security"]["final_decision"],
        envelope["security"]["likely_attack_type"],
        envelope["security"]["classical_signature_valid"],
    )

    return envelope
