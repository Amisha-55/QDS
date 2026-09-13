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

        _, aggregate_error, _, decision = run_multi_state_test(
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

    # Security metric counters
    true_negative = 0
    false_positive = 0
    true_positive = 0
    false_negative = 0

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

        # Calculate security metrics
        if attack is None:

            # Legitimate signature
            true_negative += correct
            false_positive += incorrect

        else:

            # Attack
            true_positive += correct
            false_negative += incorrect

        print("----------------------------------------")
        print(name)
        print(f"Correct Decisions: {correct}/{EXPERIMENTS}")
        print(f"Incorrect Decisions: {incorrect}/{EXPERIMENTS}")
        print(f"Classification Accuracy: {accuracy * 100:.2f}%")
        print(f"Mean Aggregate Error: {mean_error:.4f}")
        print(f"Minimum Error: {min_error:.4f}")
        print(f"Maximum Error: {max_error:.4f}")

    overall_accuracy = total_correct / total_experiments

    # Security metrics
    total_attacks = true_positive + false_negative
    total_legitimate = true_negative + false_positive

    detection_rate = (
        true_positive / total_attacks
        if total_attacks > 0
        else 0
    )

    false_positive_rate = (
        false_positive / total_legitimate
        if total_legitimate > 0
        else 0
    )

    false_negative_rate = (
        false_negative / total_attacks
        if total_attacks > 0
        else 0
    )

    print()
    print("========================================")
    print("          OVERALL PERFORMANCE")
    print("========================================")

    print(f"Total Correct Decisions: {total_correct}")
    print(f"Total Experiments: {total_experiments}")
    print(f"Overall Accuracy: {overall_accuracy * 100:.2f}%")

    print()
    print("========================================")
    print("           SECURITY METRICS")
    print("========================================")

    print(f"True Positives: {true_positive}")
    print(f"True Negatives: {true_negative}")
    print(f"False Positives: {false_positive}")
    print(f"False Negatives: {false_negative}")

    print()
    print(f"Detection Rate: {detection_rate * 100:.2f}%")
    print(f"False Positive Rate: {false_positive_rate * 100:.2f}%")
    print(f"False Negative Rate: {false_negative_rate * 100:.2f}%")