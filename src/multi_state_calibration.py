from noisy_channel import run_noisy_experiment
from config import SHOTS, NOISE_PROBABILITY
import statistics


def calculate_error_rate(counts, shots):
    return counts.get("1", 0) / shots


def run_multi_state_experiment(
    shots=SHOTS,
    noise_probability=NOISE_PROBABILITY
):
    states = ["Z", "X", "Y"]

    total_errors = 0
    total_shots = 0

    for state in states:

        counts = run_noisy_experiment(
            state=state,
            attack=None,
            noise_probability=noise_probability,
            shots=shots
        )

        total_errors += counts.get("1", 0)
        total_shots += shots

    aggregate_error_rate = total_errors / total_shots

    return aggregate_error_rate

if __name__ == "__main__":

    print("========================================")
    print("   MULTI-STATE THRESHOLD CALIBRATION")
    print("========================================")

    shots = SHOTS
    noise_probability = NOISE_PROBABILITY
    experiments = 20

    aggregate_errors = []

    for i in range(1, experiments + 1):

        error_rate = run_multi_state_experiment(
            shots=shots,
            noise_probability=noise_probability
        )

        aggregate_errors.append(error_rate)

        print(
            f"Experiment {i:02d}: "
            f"Aggregate Error Rate = {error_rate:.4f}"
        )

    mean_error = statistics.mean(aggregate_errors)
    std_error = statistics.stdev(aggregate_errors)
    max_error = max(aggregate_errors)

    threshold = mean_error + (3 * std_error)

    # Make sure the threshold is above every
    # legitimate calibration observation.
    threshold = max(threshold, max_error)

    print("\n========================================")
    print("        CALIBRATION RESULTS")
    print("========================================")

    print(f"Mean Error Rate:       {mean_error:.4f}")
    print(f"Standard Deviation:    {std_error:.4f}")
    print(f"Maximum Error Rate:    {max_error:.4f}")
    print(f"Calibrated Threshold:  {threshold:.4f}")

    print("\nDecision Rule:")
    print(
        f"Aggregate Error Rate <= {threshold:.4f} "
        "-> LEGITIMATE"
    )

    print(
        f"Aggregate Error Rate > {threshold:.4f} "
        "-> SUSPICIOUS / ATTACK"
    )