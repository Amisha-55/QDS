from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error
import numpy as np

SHOTS = 1000

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
    """Prepare Z, X or Y Pauli eigenstate."""

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
    """Measure the qubit in Z, X or Y basis."""

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
    """
    Create a depolarizing noise model.

    The error is applied to the identity gate used as
    a channel placeholder before measurement.
    """

    noise_model = NoiseModel()

    if noise_level > 0:
        error = depolarizing_error(noise_level, 1)
        noise_model.add_all_qubit_quantum_error(
            error,
            ["id"]
        )

    return noise_model


def run_experiment(state, basis, noise_level, shots=SHOTS):
    """Run one state/basis experiment under channel noise."""

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    # Identity gate represents the quantum channel.
    qc.id(0)

    measure_in_basis(qc, basis)

    noise_model = create_noise_model(noise_level)

    simulator = AerSimulator(
        noise_model=noise_model
    )

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    counts = result.get_counts()

    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    p1 = one_count / shots

    return p1


def calculate_fingerprint_score(noise_level):
    """Calculate aggregate deviation score."""

    deviations = []

    for state in STATES:

        for basis in BASES:

            observed_p1 = run_experiment(
                state=state,
                basis=basis,
                noise_level=noise_level,
                shots=SHOTS
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
    print("       NOISE-AWARE CALIBRATION")
    print("========================================")

    print(f"\nShots per cell: {SHOTS}")

    print("\nNoise Level → Aggregate Deviation")
    print("----------------------------------------")

    scores = []

    for noise_level in NOISE_LEVELS:

        score = calculate_fingerprint_score(
            noise_level
        )

        scores.append(
            (noise_level, score)
        )

        print(
            f"Noise={noise_level:.2f} "
            f"→ Score={score:.4f}"
        )

    print("----------------------------------------")

    print("\nCalibration Summary")

    for noise_level, score in scores:

        print(
            f"Noise {noise_level:.2f} "
            f"| Aggregate Score {score:.4f}"
        )


if __name__ == "__main__":
    main()