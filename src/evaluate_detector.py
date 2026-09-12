from multi_state_detector import run_multi_state_test
from config import SHOTS, NOISE_PROBABILITY
import statistics


EXPERIMENTS = 30

ATTACKS = [
    None,
    "bit_flip",
    "phase_flip",
    "bit_phase_flip"
]


def evaluate_attack(attack):
    correct = 0
    incorrect = 0
    error_rates = []

    expected_decision = (
        "LEGITIMATE"
        if attack is None
        else "SUSPICIOUS / ATTACK"
    )

    for _ in range(EXPERIMENTS):

        _, aggregate_error, decision = run_multi_state_test(
            attack=attack,
            shots=SHOTS,
            noise_probability=NOISE_PROBABILITY
        )

        error_rates.append(aggregate_error)

        if decision == expected_decision:
            correct += 1
        else:
            incorrect += 1

    return correct, incorrect, error_rates


if __name__ == "__main__":

    print("========================================")
    print("       DETECTOR PERFORMANCE EVALUATION")
    print("========================================")

    print(f"Experiments per class: {EXPERIMENTS}")
    print(f"Shots per state: {SHOTS}")
    print(f"Noise probability: {NOISE_PROBABILITY}")
    print()

    total_correct = 0
    total_experiments = 0

    results = {}

    for attack in ATTACKS:

        name = "LEGITIMATE" if attack is None else attack.upper()

        correct, incorrect, error_rates = evaluate_attack(attack)

        accuracy = correct / EXPERIMENTS

        mean_error = statistics.mean(error_rates)
        min_error = min(error_rates)
        max_error = max(error_rates)

        results[name] = {
            "correct": correct,
            "incorrect": incorrect,
            "accuracy": accuracy,
            "mean_error": mean_error,
            "min_error": min_error,
            "max_error": max_error
        }

        total_correct += correct
        total_experiments += EXPERIMENTS

        print("----------------------------------------")
        print(name)
        print(f"Correct Decisions: {correct}/{EXPERIMENTS}")
        print(f"Incorrect Decisions: {incorrect}/{EXPERIMENTS}")
        print(f"Classification Accuracy: {accuracy * 100:.2f}%")
        print(f"Mean Aggregate Error: {mean_error:.4f}")
        print(f"Minimum Error: {min_error:.4f}")
        print(f"Maximum Error: {max_error:.4f}")

    overall_accuracy = total_correct / total_experiments

    print()
    print("========================================")
    print("          OVERALL PERFORMANCE")
    print("========================================")

    print(f"Total Correct Decisions: {total_correct}")
    print(f"Total Experiments: {total_experiments}")
    print(f"Overall Accuracy: {overall_accuracy * 100:.2f}%")