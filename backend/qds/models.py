from dataclasses import dataclass, field, asdict
from typing import Optional, Dict, Any, List


class SecurityDecision:
    TRUSTED = "TRUSTED"
    INVALID_SUSPICIOUS = "INVALID / SUSPICIOUS"


class LikelyAttackType:
    LEGITIMATE = "LEGITIMATE"
    FORGERY = "FORGERY"
    IMPERSONATION = "IMPERSONATION"
    REPLAY = "REPLAY"
    CHANNEL_ATTACK = "CHANNEL_ATTACK"
    QUANTUM_TAMPER = "QUANTUM_TAMPER"
    UNKNOWN = "UNKNOWN"


@dataclass
class QuantumStats:
    bit_count: int
    overall_accuracy: float
    shots: int
    bases_used: List[str] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class SecureMessageResult:
    success: bool
    packet: Optional[Dict[str, Any]] = None
    signature_id: Optional[str] = None
    timestamp: Optional[str] = None
    sender_id: Optional[str] = None
    receiver_id: Optional[str] = None
    message: Optional[str] = None
    quantum_stats: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class VerificationResult:
    success: bool
    signer_id: Optional[str] = None
    receiver_id: Optional[str] = None
    message: Optional[str] = None
    signature_id: Optional[str] = None
    timestamp: Optional[str] = None
    classical_signature_valid: bool = False
    replay_detected: bool = False
    qds_valid: bool = False
    qds_accuracy: float = 0.0
    attack_detected: bool = False
    likely_attack_type: str = LikelyAttackType.UNKNOWN
    final_decision: str = SecurityDecision.INVALID_SUSPICIOUS
    details: Dict[str, Any] = field(default_factory=dict)
    error: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)
