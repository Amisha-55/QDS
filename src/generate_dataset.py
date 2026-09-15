import csv
import os
import uuid

from noisy_channel import (
    run_noisy_experiment,
    calculate_statistics
)

from config import SHOTS, NOISE_PROBABILITY, THRESHOLD


OUTPUT_FILE = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "data",
    "qds_security_dataset.csv"
)

STATES = ["Z", "X", "Y"]

ATTACKS = [
    (None, "LEGITIMATE"),
    ("bit_flip", "BIT_FLIP"),
    ("phase_flip", "PHASE_FLIP"),
    ("bit_phase_flip", "BIT_PHASE_FLIP")
]

EXPERIMENTS_PER_CLASS = 30


def generate_dataset():

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)

    rows = []

    experiment_number = 1

    print("========================================")
    print("       QDS SECURITY DATASET GENERATOR")
    print("========================================")

    print(f"\nStates: {STATES}")
    print(f"Experiments per attack class: {EXPERIMENTS_PER_CLASS}")
    print(f"Shots per state: {SHOTS}")
    print(f"Noise probability: {NOISE_PROBABILITY}")
    print(f"Threshold: {THRESHOLD:.4f}")

    for attack, attack_label in ATTACKS:

        print(f"\nGenerating: {attack_label}")

        for experiment in range(EXPERIMENTS_PER_CLASS):

            total_zero = 0
            total_one = 0

            for state in STATES:

                counts = run_noisy_experiment(
                    state=state,
                    attack=attack,
                    noise_probability=NOISE_PROBABILITY,
                    shots=SHOTS
                )

                zero_count = counts.get("0", 0)
                one_count = counts.get("1", 0)

                total_zero += zero_count
                total_one += one_count

                p0, p1, error_rate = calculate_statistics(
                    counts,
                    SHOTS
                )

                decision = (
                    "LEGITIMATE"
                    if error_rate <= THRESHOLD
                    else "SUSPICIOUS / ATTACK"
                )

                rows.append({
                    "experiment_id": str(uuid.uuid4()),
                    "experiment_number": experiment_number,
                    "attack_type": attack_label,
                    "quantum_state": state,
                    "shots": SHOTS,
                    "zero_count": zero_count,
                    "one_count": one_count,
                    "probability_0": round(p0, 4),
                    "probability_1": round(p1, 4),
                    "error_rate": round(error_rate, 4),
                    "noise_probability": NOISE_PROBABILITY,
                    "threshold": THRESHOLD,
                    "decision": decision
                })

            experiment_number += 1

    fieldnames = [
        "experiment_id",
        "experiment_number",
        "attack_type",
        "quantum_state",
        "shots",
        "zero_count",
        "one_count",
        "probability_0",
        "probability_1",
        "error_rate",
        "noise_probability",
        "threshold",
        "decision"
    ]

    with open(
        OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8"
    ) as file:

        writer = csv.DictWriter(
            file,
            fieldnames=fieldnames
        )

        writer.writeheader()
        writer.writerows(rows)

    print("\n========================================")
    print("          DATASET GENERATION DONE")
    print("========================================")

    print(f"\nTotal rows generated: {len(rows)}")
    print(f"Dataset saved to:")
    print(OUTPUT_FILE)

    print("\nExpected:")
    print("4 attack classes × 30 experiments × 3 states")
    print("= 360 rows")


if __name__ == "__main__":
    generate_dataset()