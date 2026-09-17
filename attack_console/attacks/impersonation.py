"""
Impersonation Attack Wrapper

Invokes the existing research function `simulate_impersonation` from `src/impersonation_attack.py`.
Generates a rogue Ed25519 keypair and signs the packet while claiming the identity
of the legitimate signer.
"""

import os
import sys
import uuid
import base64
from datetime import datetime, timezone
from typing import Any, Dict

# Ensure existing research modules in src/ can be imported
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from impersonation_attack import simulate_impersonation
from classical_signature import generate_key_pair, sign_data
from secure_packet import create_secure_packet, canonical_json


def prepare_impersonation_packet(
    message: str,
    claimed_signer_id: str = "X",
) -> Dict[str, Any]:
    """
    Produce an impersonated packet using the existing research logic.
    Signs the packet with an attacker's rogue key while claiming to be claimed_signer_id.
    Embeds signature_id and timestamp for protocol parity.
    """
    attacker_private, _ = generate_key_pair()
    packet = create_secure_packet(
        message,
        attacker_private,
        claimed_signer_id,
    )

    # Attach signature_id and timestamp, signed by the attacker
    signature_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()
    packet["payload"]["signature_id"] = signature_id
    packet["payload"]["timestamp"] = timestamp

    payload_bytes = canonical_json(packet["payload"])
    new_sig = sign_data(attacker_private, payload_bytes)
    packet["classical_signature"] = base64.b64encode(new_sig).decode("ascii")

    return packet
