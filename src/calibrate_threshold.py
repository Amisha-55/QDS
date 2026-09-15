from noisy_channel import run_noisy_experiment
from config import SHOTS, STATES, BASES


NOISE_PROBABILITY = 0.02
REPEATS = 50


def expected_probability_one(state, basis):
    if state == basis:
        return 0.0

    return 0.5


def calculate_score(
    shots=SHOTS,
    noise_probability=NOISE_PROBABILITY
):

    total_deviation = 0.0
    experiment_count = 0

    for state in STATES:

        for basis in BASES:

            counts = run_noisy_experiment(
                state=state,
                attack=None,
                noise_probability=noise_probability,
                shots=shots,
                measurement_basis=basis
            )

            probability_1 = counts.get("1", 0) / shots

            expected_p1 = expected_probability_one(
                state,
                basis
            )

            deviation = abs(
                probability_1 - expected_p1
            )

            total_deviation += deviation
            experiment_count += 1

    return total_deviation / experiment_count


if __name__ == "__main__":

    print("========================================")
    print("     LEGITIMATE THRESHOLD CALIBRATION")
    print("========================================")

    print(f"\nNoise Probability: {NOISE_PROBABILITY}")
    print(f"Shots per experiment: {SHOTS}")
    print(f"Calibration repeats: {REPEATS}")

    scores = []

    for i in range(REPEATS):

        score = calculate_score()

        scores.append(score)

        print(
            f"Run {i + 1:02d}/{REPEATS} "
            f"→ Score = {score:.4f}"
        )

    mean_score = sum(scores) / len(scores)

    variance = sum(
        (score - mean_score) ** 2
        for score in scores
    ) / len(scores)

    std_score = variance ** 0.5

    minimum = min(scores)
    maximum = max(scores)

    threshold = mean_score + 3 * std_score

    threshold = max(
        threshold,
        maximum
    )

    print("\n========================================")
    print("          CALIBRATION RESULTS")
    print("========================================")

    print(f"Mean Score:      {mean_score:.4f}")
    print(f"Std Deviation:   {std_score:.4f}")
    print(f"Minimum Score:   {minimum:.4f}")
    print(f"Maximum Score:   {maximum:.4f}")

    print("\n----------------------------------------")

    print(
        f"Recommended Threshold: "
        f"{threshold:.4f}"
    )

    print("----------------------------------------")

    print(
        "\nThis threshold is calibrated from "
        "legitimate experiments only."
    )

    print(
        "It should be validated against attack "
        "experiments before being treated as final."
    )