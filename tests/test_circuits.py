"""
Unit Tests: Quantum Circuit & Teleportation Fidelity
Tests Pauli eigenstates and Bell-state teleportation.
"""

import os
import sys
import pytest

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from teleportation import teleport_state, calculate_bob_probability


def test_pauli_z_teleportation():
    """State |0> teleportation must yield Bob P(0) >= 0.98."""
    counts = teleport_state("Z", shots=1000)
    p0, p1 = calculate_bob_probability(counts, shots=1000)
    assert p0 >= 0.98
    assert p1 <= 0.02


def test_pauli_x_teleportation():
    """State |+> teleportation measured in X basis yields P(0) >= 0.98."""
    counts = teleport_state("X", shots=1000)
    p0, p1 = calculate_bob_probability(counts, shots=1000)
    assert p0 >= 0.98
    assert p1 <= 0.02


def test_pauli_y_teleportation():
    """State |+i> teleportation measured in Y basis yields P(0) >= 0.98."""
    counts = teleport_state("Y", shots=1000)
    p0, p1 = calculate_bob_probability(counts, shots=1000)
    assert p0 >= 0.98
    assert p1 <= 0.02


def test_invalid_teleportation_input():
    """Invalid basis state must raise ValueError."""
    with pytest.raises(ValueError):
        teleport_state("INVALID_STATE", shots=100)
