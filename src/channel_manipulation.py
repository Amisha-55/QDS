from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def prepare_state(qc, state):
    """
    Prepare a Pauli eigenstate.

    Z basis:
        |0>

    X basis:
        |+>

    Y basis:
        |+i>
    """

    if state == "Z":
        pass

    elif state == "X":
        qc.h(0)

    elif state == "Y":
        qc.h(0)
        qc.s(0)

    else:
        raise ValueError("State must be Z, X, or Y")


def apply_attack(qc, attack):
    """Apply a simulated Pauli channel manipulation."""

    if attack == "bit_flip":
        qc.x(0)

    elif attack == "phase_flip":
        qc.z(0)

    elif attack == "bit_phase_flip":
        qc.y(0)

    elif attack is None:
        pass

    else:
        raise ValueError("Unknown attack")


def measure_in_basis(qc, basis):
    """Perform projective measurement in X, Y, or Z basis."""

    if basis == "X":
        qc.h(0)

    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)

    elif basis == "Z":
        pass

    else:
        raise ValueError("Basis must be X, Y, or Z")

    qc.measure(0, 0)


def run_experiment(state, attack=None, measurement_basis=None, shots=1000):

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    apply_attack(qc, attack)

    if measurement_basis is None:
        measurement_basis = state

    measure_in_basis(qc, measurement_basis)

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    return result.get_counts()


def probabilities(counts, shots=1000):

    p0 = counts.get("0", 0) / shots
    p1 = counts.get("1", 0) / shots

    return p0, p1


print("========================================")
print("  PAULI EIGENSTATE CHANNEL EXPERIMENT")
print("========================================")

states = ["Z", "X", "Y"]
attacks = [None, "bit_flip", "phase_flip", "bit_phase_flip"]


for state in states:

    print(f"\n{'=' * 40}")
    print(f"STATE: {state}-EIGENSTATE")
    print(f"{'=' * 40}")

    for attack in attacks:

        name = "LEGITIMATE" if attack is None else attack.upper()

        counts = run_experiment(
            state=state,
            attack=attack,
            measurement_basis=state
        )

        p0, p1 = probabilities(counts)

        print(f"\n{name}")
        print("Measurement:", counts)
        print(f"P(0): {p0:.3f}")
        print(f"P(1): {p1:.3f}")