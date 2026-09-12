from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error
import statistics


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


def create_noise_model(noise_probability):
    noise_model = NoiseModel()

    noise = depolarizing_error(noise_probability, 1)

    noise_model.add_quantum_error(
        noise,
        ["id"],
        [0]
    )

    return noise_model


def run_legitimate_experiment(
    state,
    noise_probability=0.02,
    shots=1000
):
    qc = QuantumCircuit(1, 1)

    # Prepare legitimate Pauli eigenstate
    prepare_state(qc, state)

    # Simulated quantum channel noise
    qc.id(0)

    # Projective measurement in matching basis
    measure_in_basis(qc, state)

    simulator = AerSimulator()

    noise_model = create_noise_model(noise_probability)

    result = simulator.run(
        qc,
        shots=shots,
        noise_model=noise_model,
        optimization_level=0
    ).result()

    return result.get_counts()


def calculate_error_rate(counts, shots):
    unexpected_count = counts.get("1", 0)

    return unexpected_count / shots


print("========================================")
print("  NOISY CHANNEL THRESHOLD CALIBRATION")
print("========================================")

states = ["Z", "X", "Y"]

experiments = 20
shots = 1000
noise_probability = 0.02

print(f"\nNoise Parameter: {noise_probability}")
print(f"Experiments per state: {experiments}")
print(f"Shots per experiment: {shots}")


all_error_rates = []


for state in states:

    print(f"\n{'=' * 40}")
    print(f"STATE: {state}-EIGENSTATE")
    print(f"{'=' * 40}")

    error_rates = []

    for i in range(1, experiments + 1):

        counts = run_legitimate_experiment(
            state=state,
            noise_probability=noise_probability,
            shots=shots
        )

        error_rate = calculate_error_rate(
            counts,
            shots
        )

        error_rates.append(error_rate)

        print(
            f"Experiment {i:02d}: "
            f"Counts={counts}, "
            f"Error Rate={error_rate:.4f}"
        )

    mean_error = statistics.mean(error_rates)
    std_error = statistics.stdev(error_rates)
    max_error = max(error_rates)

    print("\nState Statistics")
    print(f"Mean Error Rate : {mean_error:.4f}")
    print(f"Std Deviation   : {std_error:.4f}")
    print(f"Maximum Error   : {max_error:.4f}")

    all_error_rates.extend(error_rates)


print(f"\n{'=' * 40}")
print("OVERALL CALIBRATION")
print(f"{'=' * 40}")

overall_mean = statistics.mean(all_error_rates)
overall_std = statistics.stdev(all_error_rates)
overall_max = max(all_error_rates)

print(f"Overall Mean Error : {overall_mean:.4f}")
print(f"Overall Std        : {overall_std:.4f}")
print(f"Overall Maximum    : {overall_max:.4f}")


# Conservative threshold:
# mean + 3 standard deviations
threshold = overall_mean + (3 * overall_std)

# Ensure the threshold is not lower than the
# maximum observed legitimate error.
threshold = max(threshold, overall_max)

print(f"\nCalibrated Error Threshold: {threshold:.4f}")
print(f"Calibrated Acceptance Accuracy Target: {(1 - threshold) * 100:.2f}%")

print("\nCalibration complete.")