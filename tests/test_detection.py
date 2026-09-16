"""
Unit Tests: Non-AI Statistical Threat Detection Engine
Tests Hoeffding bounds, Likelihood Ratio Tests, and Thresholding.
"""

import os
import sys
import pytest

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from math_model import QDSMathematicalModel
from threat_detector import comprehensive_threat_classification, detect_threat


def test_legitimate_measurement_classification():
    """Clean measurement (low error) should be flagged as LEGITIMATE."""
    counts = {"0": 985, "1": 15}
    shots = 1000
    res = comprehensive_threat_classification(counts, shots, threshold=0.05)
    assert res["status"] == "LEGITIMATE"
    assert res["threat_type"] == "NONE"
    assert res["fidelity"] >= 0.95


def test_bit_flip_attack_classification():
    """Severe bit-flip tampering (high error) should trigger CRITICAL_ATTACK."""
    counts = {"0": 30, "1": 970}
    shots = 1000
    res = comprehensive_threat_classification(counts, shots, threshold=0.05)
    assert res["status"] == "CRITICAL_ATTACK"
    assert res["threat_type"] == "ACTIVE_PAULI_BIT_FLIP"
    assert res["fidelity"] <= 0.10


def test_eavesdropping_intercept_resend_classification():
    """Eavesdropping generates ~50% error rate."""
    counts = {"0": 510, "1": 490}
    shots = 1000
    res = comprehensive_threat_classification(counts, shots, threshold=0.05)
    assert res["status"] == "EAVESDROPPING_DETECTED"
    assert res["threat_type"] == "INTERCEPT_RESEND_OR_DEPOLARIZING"


def test_hoeffding_confidence_interval():
    """Confidence interval must tightly enclose observed rate."""
    lower, upper, margin = QDSMathematicalModel.calculate_confidence_interval(
        observed_error=0.02, shots=1000, confidence_level=0.99
    )
    assert 0.0 <= lower <= 0.02
    assert 0.02 <= upper <= 1.0
    assert margin < 0.06


def test_forgery_probability_decay():
    """P_forgery must strictly decrease as qubit length N increases."""
    p_8 = QDSMathematicalModel.calculate_forgery_probability(8, error_rate=0.02, threshold=0.15)
    p_32 = QDSMathematicalModel.calculate_forgery_probability(32, error_rate=0.02, threshold=0.15)
    p_128 = QDSMathematicalModel.calculate_forgery_probability(128, error_rate=0.02, threshold=0.15)

    assert p_8 > p_32 > p_128
    assert p_128 < 0.05
