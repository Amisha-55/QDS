import os
import sys

# Ensure src/ is automatically added to sys.path when importing backend.qds
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

# Ensure QDS root is also in sys.path
ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

from backend.qds.models import (
    SecureMessageResult,
    VerificationResult,
    QuantumStats,
    SecurityDecision,
    LikelyAttackType,
)
from backend.qds.exceptions import (
    QDSServiceError,
    KeyManagementError,
    PacketValidationError,
    CryptoError,
)
from backend.qds.key_manager import KeyManager
from backend.qds.service import QDSService

# Default global service instance for convenient one-off calls
_default_service = QDSService()
secure_message = _default_service.secure_message
verify_message = _default_service.verify_message
reset_replay_cache = _default_service.reset_replay_cache

__all__ = [
    "QDSService",
    "KeyManager",
    "SecureMessageResult",
    "VerificationResult",
    "QuantumStats",
    "SecurityDecision",
    "LikelyAttackType",
    "QDSServiceError",
    "KeyManagementError",
    "PacketValidationError",
    "CryptoError",
    "secure_message",
    "verify_message",
    "reset_replay_cache",
]
