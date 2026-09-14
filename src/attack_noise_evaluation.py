from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import depolarizing_error
import statistics

SHOTS = 1000
REPEATS = 20
NOISE_LEVEL = 0.02

# Preliminary threshold based on previous legitimate calibration:
# Mean = 0.0113, Std = 0.0025
# Mean + 3*Std = 0.0188
THRESHOLD = 0.0188

STATES = ["Z", "X", "Y"]
BASES = ["Z", "X", "Y"]
ATTACKS = [
    "LEGITIMATE",
    "BIT_FLIP",
    "PHASE_FLIP",
    "BIT_PHASE_FLIP"
]


def prepare_state(qc, state):
    if state == "Z":
        pass
    elif state == "X":
        qc.h(0)
    elif state == "Y":
        qc.h(0)
        qc.s(0)


def apply_attack(qc, attack):
    if attack == "LEGITIMATE":
        pass
    elif attack == "BIT_FLIP":
        qc.x(0)
    elif attack == "PHASE_FLIP":
        qc.z(0)
    elif attack == "BIT_PHASE_FLIP":
        qc.y(0)


def measure_in_basis(qc, basis):
    if basis == "Z":
        pass
    elif basis == "X":
        qc.h(0)
    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)

    qc.measure(0, 0)


def run_experiment(state, basis, attack):
    qc = QuantumCircuit(1, 1)

    # Prepare quantum state
    prepare_state(qc, state)

    # Apply simulated attack
    apply_attack(qc, attack)

    # Channel placeholder
    qc.id(0)

    # Measurement
    measure_in_basis(qc, basis)

    # 2% depolarizing channel noise
    noise = depolarizing_error(NOISE_LEVEL, 1)

    simulator = AerSimulator()
    simulator.set_options()

    # Add noise specifically to the channel placeholder
    noisy_simulator = AerSimulator(
        noise_model=build_noise_model(noise)
    )

    result = noisy_simulator.run(
        qc,
        shots=SHOTS
    ).result()

    counts = result.get_counts()

    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    return one_count / SHOTS


def build_noise_model(noise):
    from qiskit_aer.noise import NoiseModel

    noise_model = NoiseModel()
    noise_model.add_all_qubit_quantum_error(
        noise,
        ["id"]
    )

    return noise_model


def calculate_score(attack):
    expected_scores = []

    for state in STATES:
        for basis in BASES:

            observed_p1 = run_experiment(
                state,
                basis,
                attack
            )

            # Expected legitimate behaviour
            if state == basis:
                expected_p1 = 0.0
            else:
                expected_p1 = 0.5

            deviation = abs(observed_p1 - expected_p1)
            expected_scores.append(deviation)

    return statistics.mean(expected_scores)


def main():

    print("=" * 60)
    print("       ATTACK + NOISE SECURITY EVALUATION")
    print("=" * 60)

    print(f"\nNoise level : {NOISE_LEVEL}")
    print(f"Shots/run   : {SHOTS}")
    print(f"Repeats     : {REPEATS}")
    print(f"Threshold   : {THRESHOLD}")
    print("\nThreshold is PRELIMINARY and based on previous")
    print("legitimate 2% noise calibration.\n")

    for attack in ATTACKS:

        print("\n" + "-" * 60)
        print(f"ATTACK TYPE: {attack}")
        print("-" * 60)

        scores = []

        for run in range(1, REPEATS + 1):

            score = calculate_score(attack)
            scores.append(score)

            if score > THRESHOLD:
                decision = "ATTACK DETECTED"
            else:
                decision = "ACCEPTED"

            print(
                f"Run {run:02d} → "
                f"Score={score:.4f} → "
                f"{decision}"
            )

        mean_score = statistics.mean(scores)
        std_score = statistics.stdev(scores)
        min_score = min(scores)
        max_score = max(scores)

        detections = sum(
            score > THRESHOLD
            for score in scores
        )

        detection_rate = detections / REPEATS

        print("\nSummary:")
        print(f"Mean          : {mean_score:.4f}")
        print(f"Std           : {std_score:.4f}")
        print(f"Min           : {min_score:.4f}")
        print(f"Max           : {max_score:.4f}")
        print(f"Detections    : {detections}/{REPEATS}")
        print(f"Detection Rate: {detection_rate:.2%}")


if __name__ == "__main__":
    main()