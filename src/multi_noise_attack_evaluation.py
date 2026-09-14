import numpy as np
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error


SHOTS = 1000
REPEATS = 20

NOISE_LEVELS = [0.00, 0.01, 0.02, 0.05, 0.10]

CALIBRATED_THRESHOLDS = {
    0.00: 0.0133,
    0.01: 0.0187,
    0.02: 0.0188,
    0.05: 0.0255,
    0.10: 0.0331,
}

STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]

ATTACKS = [
    "LEGITIMATE",
    "BIT_FLIP",
    "PHASE_FLIP",
    "BIT_PHASE_FLIP",
]


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
        raise ValueError("Unknown attack type")


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


def build_simulator(noise_level):
    """
    Build an Aer simulator with depolarizing noise.

    The identity gate is used as the simulated channel
    location where the noise is applied.
    """

    noise = depolarizing_error(noise_level, 1)

    noise_model = NoiseModel()

    noise_model.add_all_qubit_quantum_error(
        noise,
        ["id"]
    )

    return AerSimulator(noise_model=noise_model)


def run_experiment(state, basis, attack, simulator):
    """Run one state/basis experiment."""

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    apply_attack(qc, attack)

    qc.id(0)

    measure_in_basis(qc, basis)

    result = simulator.run(
        qc,
        shots=SHOTS
    ).result()

    counts = result.get_counts()

    one_count = counts.get("1", 0)

    return one_count / SHOTS


def expected_probability_1(state, basis):
    """
    Expected P(1) for the legitimate experiment.

    Matching basis:
        P(1) = 0

    Mismatched basis:
        P(1) = 0.5
    """

    if state == basis:
        return 0.0

    return 0.5


def calculate_score(attack, simulator):
    """
    Calculate the mean absolute deviation from the
    legitimate expected distribution across all
    9 state/basis combinations.
    """

    deviations = []

    for state in STATES:
        for basis in BASES:

            observed_p1 = run_experiment(
                state,
                basis,
                attack,
                simulator
            )

            expected_p1 = expected_probability_1(
                state,
                basis
            )

            deviations.append(
                abs(observed_p1 - expected_p1)
            )

    return float(np.mean(deviations))


def calculate_statistics(scores):
    """Calculate summary statistics."""

    return {
        "mean": float(np.mean(scores)),
        "std": float(np.std(scores)),
        "min": float(np.min(scores)),
        "max": float(np.max(scores)),
    }


def main():

    print("=" * 90)
    print("             MULTI-NOISE ATTACK EVALUATION")
    print("=" * 90)

    print(f"\nShots per experiment : {SHOTS}")
    print(f"Independent repeats  : {REPEATS}")
    print(f"Noise levels         : {NOISE_LEVELS}")

    all_results = {}

    for noise_level in NOISE_LEVELS:

        threshold = CALIBRATED_THRESHOLDS[noise_level]

        print("\n" + "=" * 90)
        print(f"NOISE LEVEL: {noise_level:.2f}")
        print(f"PRELIMINARY THRESHOLD: {threshold:.4f}")
        print("=" * 90)

        simulator = build_simulator(noise_level)

        all_results[noise_level] = {}

        for attack in ATTACKS:

            print(f"\nRunning {attack}...")

            scores = []

            for _ in range(REPEATS):

                score = calculate_score(
                    attack,
                    simulator
                )

                scores.append(score)

            statistics = calculate_statistics(scores)

            detections = sum(
                score > threshold
                for score in scores
            )

            rate = (
                detections / REPEATS
            ) * 100

            all_results[noise_level][attack] = {
                **statistics,
                "detections": detections,
                "rate": rate,
            }

            print(
                f"  Mean : {statistics['mean']:.4f}"
            )

            print(
                f"  Std  : {statistics['std']:.4f}"
            )

            print(
                f"  Min  : {statistics['min']:.4f}"
            )

            print(
                f"  Max  : {statistics['max']:.4f}"
            )

            if attack == "LEGITIMATE":

                print(
                    f"  False Positives : "
                    f"{detections}/{REPEATS}"
                )

                print(
                    f"  False Positive Rate : "
                    f"{rate:.1f}%"
                )

            else:

                print(
                    f"  Attack Detection : "
                    f"{rate:.1f}% "
                    f"({detections}/{REPEATS})"
                )

    print("\n\n")
    print("=" * 115)
    print("                         MULTI-NOISE SUMMARY")
    print("=" * 115)

    header = (
        f"{'Noise':<8}"
        f"{'Threshold':<12}"
        f"{'Legit Mean':<14}"
        f"{'Legit Max':<14}"
        f"{'Legit FPR':<12}"
        f"{'Bit Flip':<14}"
        f"{'Phase Flip':<14}"
        f"{'Bit-Phase':<14}"
    )

    print(header)
    print("-" * 115)

    for noise_level in NOISE_LEVELS:

        threshold = CALIBRATED_THRESHOLDS[noise_level]

        legitimate = all_results[
            noise_level
        ]["LEGITIMATE"]

        bit_flip = all_results[
            noise_level
        ]["BIT_FLIP"]

        phase_flip = all_results[
            noise_level
        ]["PHASE_FLIP"]

        bit_phase = all_results[
            noise_level
        ]["BIT_PHASE_FLIP"]

        print(
            f"{noise_level:<8.2f}"
            f"{threshold:<12.4f}"
            f"{legitimate['mean']:<14.4f}"
            f"{legitimate['max']:<14.4f}"
            f"{legitimate['rate']:<12.1f}"
            f"{bit_flip['rate']:<14.1f}"
            f"{phase_flip['rate']:<14.1f}"
            f"{bit_phase['rate']:<14.1f}"
        )

    print("\n")
    print("Evaluation complete.")
    print("Thresholds shown above are preliminary calibration values.")
    print("They are not yet the final production detector thresholds.")


if __name__ == "__main__":
    main()