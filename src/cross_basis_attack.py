from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

SHOTS = 1000

STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]
ATTACKS = ["LEGITIMATE", "BIT_FLIP", "PHASE_FLIP", "BIT_PHASE_FLIP"]


def prepare_state(qc, state):
    """Prepare a Pauli eigenstate."""
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
    """Apply a simulated Pauli attack."""
    if attack == "LEGITIMATE":
        pass
    elif attack == "BIT_FLIP":
        qc.x(0)
    elif attack == "PHASE_FLIP":
        qc.z(0)
    elif attack == "BIT_PHASE_FLIP":
        qc.y(0)
    else:
        raise ValueError("Unknown attack")


def measure_in_basis(qc, basis):
    """Measure the qubit in the selected Pauli basis."""
    if basis == "Z":
        pass
    elif basis == "X":
        qc.h(0)
    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)
    else:
        raise ValueError("Basis must be Z, X, or Y")

    qc.measure(0, 0)


def run_experiment(state, attack, basis, shots=SHOTS):
    """Run one state + attack + measurement experiment."""
    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)
    apply_attack(qc, attack)
    measure_in_basis(qc, basis)

    simulator = AerSimulator()
    result = simulator.run(qc, shots=shots).result()

    return result.get_counts()


def calculate_probability_one(counts, shots):
    """Calculate P(1)."""
    one_count = counts.get("1", 0)
    return one_count / shots


def main():

    print("========================================")
    print("       CROSS-BASIS ATTACK ANALYSIS")
    print("========================================")

    print(f"\nShots per experiment: {SHOTS}")

    for attack in ATTACKS:

        print("\n\n========================================")
        print(f"ATTACK: {attack}")
        print("========================================")

        for state in STATES:

            print(f"\n--- PREPARED STATE: {state} ---")

            for basis in BASES:

                counts = run_experiment(
                    state=state,
                    attack=attack,
                    basis=basis,
                    shots=SHOTS
                )

                p1 = calculate_probability_one(counts, SHOTS)

                print(
                    f"{state} state → {basis} basis | "
                    f"P(1)={p1:.3f} | {counts}"
                )


if __name__ == "__main__":
    main()