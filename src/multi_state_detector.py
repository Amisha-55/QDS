from noisy_channel import run_noisy_experiment
from config import THRESHOLD, NOISE_PROBABILITY, SHOTS


def calculate_error_rate(counts, shots):
    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    error_rate = one_count / shots

    return error_rate


def run_multi_state_test(
    attack=None,
    shots=SHOTS,
    noise_probability=NOISE_PROBABILITY
):
    states = ["Z", "X", "Y"]

    total_errors = 0
    total_shots = 0

    state_results = {}

    for state in states:

        counts = run_noisy_experiment(
            state=state,
            attack=attack,
            noise_probability=noise_probability,
            shots=shots
        )

        error_rate = calculate_error_rate(counts, shots)

        state_results[state] = {
            "counts": counts,
            "error_rate": error_rate
        }

        total_errors += counts.get("1", 0)
        total_shots += shots

    aggregate_error_rate = total_errors / total_shots

    if aggregate_error_rate <= THRESHOLD:
        decision = "LEGITIMATE"
    else:
        decision = "SUSPICIOUS / ATTACK"

    return state_results, aggregate_error_rate, decision


# ============================================
# MULTI-STATE THREAT DETECTION
# ============================================

if __name__ == "__main__":

    print("========================================")
    print("     MULTI-STATE THREAT DETECTION")
    print("========================================")

    attacks = [
        None,
        "bit_flip",
        "phase_flip",
        "bit_phase_flip"
    ]

    for attack in attacks:

        print("\n----------------------------------------")

        if attack is None:
            print("TEST: LEGITIMATE")
        else:
            print(f"TEST: {attack.upper()}")

        state_results, aggregate_error, decision = run_multi_state_test(
            attack=attack,
            shots=SHOTS,
            noise_probability=NOISE_PROBABILITY
        )

        for state, result in state_results.items():

            print(
                f"{state} STATE: "
                f"{result['counts']} | "
                f"Error Rate: {result['error_rate']:.3f}"
            )

        print(f"Aggregate Error Rate: {aggregate_error:.3f}")
        print(f"Threshold: {THRESHOLD:.4f}")
        print(f"Decision: {decision}")