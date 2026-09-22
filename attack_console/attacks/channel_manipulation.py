"""
Channel Manipulation Attack Wrapper

Invokes the existing research functions from `src/channel_manipulation.py`
and `src/noisy_channel.py` to simulate Pauli channel manipulation (bit flip, phase flip)
or quantum channel noise across the teleportation signature elements.
"""

import os
import sys
import base64
from copy import deepcopy
from typing import Any, Dict

# Ensure existing research modules in src/ can be imported
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from channel_manipulation import run_experiment
from classical_signature import sign_data
from secure_packet import canonical_json


def prepare_channel_manipulated_packet(
    legitimate_packet: Dict[str, Any],
    private_key: Any,
    attack_type: str = "bit_flip",
) -> Dict[str, Any]:
    """
    Produce a packet whose quantum transmission was corrupted by a channel attack
    (e.g., bit_flip, phase_flip, or bit_phase_flip) using the existing research functions.

    The classical Ed25519 signature is authentically signed by the sender,
    but the underlying quantum states failed channel verification.
    """
    manipulated = deepcopy(legitimate_packet)
    qds_sig = manipulated["payload"].get("qds_signature", {})
    quantum_sig = qds_sig.get("quantum_signature", {})
    elements = quantum_sig.get("elements", [])

    # Apply existing Pauli channel simulation across the quantum elements
    for elem in elements:
        basis = elem.get("basis", "Z")
        corrupted_counts = run_experiment(
            state=basis,
            attack=attack_type,
            shots=elem.get("shots", 1000),
        )
        elem["measurement_results"] = corrupted_counts
        elem["correct_shots"] = 0
        elem["accuracy"] = 0.0

    quantum_sig["overall_accuracy"] = 0.0

    # Re-sign the payload with the legitimate sender's private key
    # This demonstrates that the classical layer is valid, but the quantum channel is compromised
    payload_bytes = canonical_json(manipulated["payload"])
    new_sig = sign_data(private_key, payload_bytes)
    manipulated["classical_signature"] = base64.b64encode(new_sig).decode("ascii")

    return manipulated
