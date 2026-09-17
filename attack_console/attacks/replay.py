"""
Replay Attack Wrapper

Invokes the existing research function `simulate_replay` from `src/replay_attack.py`.
Creates a byte-for-byte replica of an already processed packet (preserving the same signature_id)
to trigger replay detection in the QDS verification layer.
"""

import os
import sys
from typing import Any, Dict

# Ensure existing research modules in src/ can be imported
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from replay_attack import simulate_replay


def prepare_replay_packet(legitimate_packet: Dict[str, Any]) -> Dict[str, Any]:
    """
    Produce a replayed packet using the existing research implementation.
    Returns a deepcopy retaining the original signature_id and cryptographic signatures.
    """
    return simulate_replay(legitimate_packet)
