"""
Integration Tests: 3-Party Non-Repudiation Arbiter Protocol
Tests dispute resolution between Alice (Signer), Bob (Receiver), and Charlie (Arbiter).
"""

import os
import sys
import pytest

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from arbiter_protocol import QDSArbiterProtocol


def test_arbiter_upheld_valid_signature():
    """Valid signature submitted by Bob must be upheld by Arbiter Charlie."""
    protocol = QDSArbiterProtocol(channel_noise=0.02)
    sim = protocol.simulate_dispute_scenario("CONFIRMED_COMMERCIAL_TRANSACTION")
    
    assert sim["bob_verification"]["decision"] == "ACCEPTED"
    assert sim["charlie_arbitration"]["ruling"] == "UPHELD_VALID_SIGNATURE"
    assert sim["non_repudiation_guaranteed"] is True
    assert sim["charlie_arbitration"]["repudiation_probability_bound"] <= 1.0


def test_arbiter_dual_threshold_invariance():
    """Arbiter threshold s_a must be strictly greater than Bob's threshold s_v."""
    protocol = QDSArbiterProtocol(channel_noise=0.03, safety_margin=0.08)
    assert protocol.s_v < protocol.s_a
    assert protocol.s_a < 0.50
