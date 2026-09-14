from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error
import numpy as np

SHOTS = 1000
REPEATS = 20

STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]

NOISE_LEVELS = [0.00, 0.01, 0.02, 0.05, 0.10]

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


def create_noise_model(noise_level):
    noise_model = NoiseModel()

    if noise_level > 0:
        error = depolarizing_error(noise_level, 1)

        noise_model.add_all_qubit_quantum_error(
            error,
            ["id"]
        )

    return noise_model


def run_experiment(state, basis, noise_level):
    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    qc.id(0)

    measure_in_basis(qc, basis)

    noise_model = create_noise_model(noise_level)

    simulator = AerSimulator(
        noise_model=noise_model
    )

    result = simulator.run(
        qc,
        shots=SHOTS
    ).result()

    counts = result.get_counts()

    one_count = counts.get("1", 0)

    return one_count / SHOTS


def calculate_score(noise_level):
    deviations = []

    for state in STATES:
        for basis in BASES:

            observed_p1 = run_experiment(
                state,
                basis,
                noise_level
            )

            expected_p1 = EXPECTED_P1[
                (state, basis)
            ]

            deviation = abs(
                observed_p1 - expected_p1
            )

            deviations.append(deviation)

    return float(np.mean(deviations))


def main():

    print("========================================")
    print("   REPEATED NOISE CALIBRATION")
    print("========================================")

    print(f"\nShots per cell : {SHOTS}")
    print(f"Repeats        : {REPEATS}")

    print("\n========================================")
    print("LEGITIMATE SCORE DISTRIBUTION")
    print("========================================")

    for noise_level in NOISE_LEVELS:

        scores = []

        print(
            f"\nTesting noise level: "
            f"{noise_level:.2f}"
        )

        for run in range(1, REPEATS + 1):

            score = calculate_score(
                noise_level
            )

            scores.append(score)

            print(
                f"Run {run:02d} → "
                f"{score:.4f}"
            )

        scores = np.array(scores)

        print("\nSummary:")
        print(
            f"Mean   : {np.mean(scores):.4f}"
        )
        print(
            f"Std    : {np.std(scores, ddof=1):.4f}"
        )
        print(
            f"Min    : {np.min(scores):.4f}"
        )
        print(
            f"Max    : {np.max(scores):.4f}"
        )

    print("\n========================================")
    print("        CALIBRATION COMPLETE")
    print("========================================")


if __name__ == "__main__":
    main()