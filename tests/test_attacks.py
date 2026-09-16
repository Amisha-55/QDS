"""
Integration Tests: Adversarial Attack Suite
Validates detection of:
1. Signature Forgery
2. Signer Impersonation
3. Replay Attacks
4. Quantum Channel Manipulation
"""

import os
import sys
import pytest

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from attack_suite import QDSAttackSuite


@pytest.fixture
def suite():
    return QDSAttackSuite(signer_id="Alice", shots=1000, threshold=0.05)


def test_clean_legitimate_transmission(suite):
    """Legitimate transmission must be deterministically accepted."""
    suite.reset_replay_cache()
    res = suite.run_clean_scenario("TEST_MSG_NORMAL")
    assert res["final_decision"] == "ACCEPT"
    assert res["detected"] is False
    assert res["classical_valid"] is True
    assert res["error_rate"] <= 0.05


def test_signature_forgery_detection(suite):
    """Tampered payload must be detected and rejected."""
    suite.reset_replay_cache()
    res = suite.run_forgery_attack("ORIGINAL_MSG", "FORGED_MSG")
    assert res["final_decision"] == "REJECT"
    assert res["detected"] is True
    assert res["threat_classification"] == "PAYLOAD_TAMPERING_FORGERY"


def test_signer_impersonation_detection(suite):
    """Spoofed signer key must be detected and rejected."""
    suite.reset_replay_cache()
    res = suite.run_impersonation_attack("SPOOFED_TRANSACTION")
    assert res["final_decision"] == "REJECT"
    assert res["detected"] is True
    assert res["threat_classification"] == "IDENTITY_SPOOFING_IMPERSONATION"


def test_replay_attack_detection(suite):
    """Replayed packet must trigger replay detector."""
    suite.reset_replay_cache()
    res = suite.run_replay_attack("REPLAY_TEST_TX")
    assert res["final_decision"] == "REJECT"
    assert res["detected"] is True
    assert res["replay_detected"] is True
    assert res["threat_classification"] == "CRYPTOGRAPHIC_REPLAY_ATTACK"


def test_channel_bit_flip_detection(suite):
    """Pauli bit-flip on channel must be detected and rejected."""
    res = suite.run_channel_manipulation("Z", "bit_flip", noise_probability=0.05)
    assert res["final_decision"] == "REJECT"
    assert res["detected"] is True
    assert res["error_rate"] > 0.05
