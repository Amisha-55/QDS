"""
Forgery Attack Wrapper

Invokes the existing research function `simulate_forgery` from `src/forgery_attack.py`
to tamper with a message payload without re-signing, breaking Ed25519 classical authenticity.
"""

import os
import sys
from typing import Any, Dict, Optional

# Ensure existing research modules in src/ can be imported
SRC_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_PATH not in sys.path:
    sys.path.insert(0, SRC_PATH)

from forgery_attack import simulate_forgery


def prepare_forgery_packet(
    legitimate_packet: Dict[str, Any],
    forged_message: Optional[str] = None,
) -> Dict[str, Any]:
    """
    Produce a forged packet using the existing research implementation.
    Modifies the message inside the packet while leaving the original signature intact.
    """
    return simulate_forgery(legitimate_packet, forged_message=forged_message)
