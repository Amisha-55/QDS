from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


SHOTS = 1000
STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]


def prepare_state(qc, state):
    """Prepare a Pauli eigenstate."""

    if state == "Z":
        # |0>
        pass

    elif state == "X":
        # |+>
        qc.h(0)

    elif state == "Y":
        # |+i>
        qc.h(0)
        qc.s(0)

    else:
        raise ValueError("State must be Z, X, or Y")


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


def run_experiment(state, basis, shots=SHOTS):
    """Prepare a state and measure it in the selected basis."""

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)
    measure_in_basis(qc, basis)

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    return result.get_counts()


def calculate_probabilities(counts, shots):
    """Calculate P(0) and P(1)."""

    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    return probability_0, probability_1


def main():

    print("========================================")
    print("      CROSS-BASIS MEASUREMENT TEST")
    print("========================================")

    print(f"\nShots per experiment: {SHOTS}")

    for state in STATES:

        print("\n----------------------------------------")
        print(f"PREPARED STATE: {state}")
        print("----------------------------------------")

        for basis in BASES:

            counts = run_experiment(
                state=state,
                basis=basis,
                shots=SHOTS
            )

            p0, p1 = calculate_probabilities(
                counts,
                SHOTS
            )

            print(
                f"{state} state → {basis} basis | "
                f"P(0)={p0:.3f}, "
                f"P(1)={p1:.3f} | "
                f"{counts}"
            )


if __name__ == "__main__":
    main()