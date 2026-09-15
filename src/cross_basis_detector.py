from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
import numpy as np


SHOTS = 1000

STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]

EXPECTED_P1 = {
    ("Z", "Z"): 0.0,
    ("Z", "X"): 0.5,
    ("Z", "Y"): 0.5,

    ("X", "Z"): 0.5,
    ("X", "X"): 0.0,
    ("X", "Y"): 0.5,

    ("Y", "Z"): 0.5,
    ("Y", "X"): 0.5,
    ("Y", "Y"): 0.0,
}


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
        raise ValueError(
            "Attack must be LEGITIMATE, BIT_FLIP, "
            "PHASE_FLIP, or BIT_PHASE_FLIP"
        )


def run_experiment(state, basis, attack="LEGITIMATE", shots=SHOTS):
    """Run one state/basis/attack experiment."""

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    apply_attack(qc, attack)

    measure_in_basis(qc, basis)

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    counts = result.get_counts()

    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    p1 = one_count / shots

    return p1, counts


def calculate_deviation(state, basis, observed_p1):
    """Calculate absolute deviation from legitimate expectation."""

    expected_p1 = EXPECTED_P1[(state, basis)]

    deviation = abs(observed_p1 - expected_p1)

    return deviation


def run_fingerprint(attack="LEGITIMATE"):
    """
    Run the complete 3-state × 3-basis experiment.

    Returns all measurement cells and the aggregate deviation score.
    """

    results = []

    deviations = []

    for state in STATES:

        for basis in BASES:

            observed_p1, counts = run_experiment(
                state=state,
                basis=basis,
                attack=attack,
                shots=SHOTS
            )

            expected_p1 = EXPECTED_P1[(state, basis)]

            deviation = calculate_deviation(
                state,
                basis,
                observed_p1
            )

            deviations.append(deviation)

            results.append({
                "state": state,
                "basis": basis,
                "expected_p1": expected_p1,
                "observed_p1": observed_p1,
                "deviation": deviation,
                "counts": counts
            })

    aggregate_score = float(np.mean(deviations))

    return results, aggregate_score


def print_results(attack, results, aggregate_score):

    print("\n========================================")
    print("      CROSS-BASIS THREAT DETECTOR")
    print("========================================")

    print(f"\nAttack scenario: {attack}")
    print(f"Shots per cell: {SHOTS}")

    print("\nMeasurement fingerprint:")
    print("----------------------------------------")

    for result in results:

        print(
            f"{result['state']} state → "
            f"{result['basis']} basis | "
            f"Expected P(1)={result['expected_p1']:.3f} | "
            f"Observed P(1)={result['observed_p1']:.3f} | "
            f"Deviation={result['deviation']:.3f}"
        )

    print("----------------------------------------")

    print(
        f"\nAggregate deviation score: "
        f"{aggregate_score:.4f}"
    )


def main():

    attacks = [
        "LEGITIMATE",
        "BIT_FLIP",
        "PHASE_FLIP",
        "BIT_PHASE_FLIP"
    ]

    for attack in attacks:

        results, aggregate_score = run_fingerprint(
            attack=attack
        )

        print_results(
            attack,
            results,
            aggregate_score
        )


if __name__ == "__main__":
    main()