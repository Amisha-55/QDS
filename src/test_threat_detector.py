from noisy_channel import run_noisy_experiment
from threat_detector import detect_threat, THRESHOLD


def calculate_error_rate(counts, shots):
    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    error_rate = probability_1

    return probability_0, probability_1, error_rate


print("========================================")
print("   QUANTUM THREAT DETECTOR - TEST")
print("========================================")

shots = 1000
noise_probability = 0.02

states = ["Z", "X", "Y"]

attacks = [
    None,
    "bit_flip",
    "phase_flip",
    "bit_phase_flip"
]

for state in states:

    print(f"\n========== {state}-STATE ==========")

    for attack in attacks:

        counts = run_noisy_experiment(
            state=state,
            attack=attack,
            noise_probability=noise_probability,
            shots=shots
        )

        p0, p1, error_rate = calculate_error_rate(
            counts,
            shots
        )

        decision = detect_threat(error_rate)

        attack_name = attack if attack else "LEGITIMATE"

        print(f"\nAttack: {attack_name}")
        print("Measurement Results:", counts)
        print(f"Error Rate: {error_rate:.3f}")
        print(f"Threshold: {THRESHOLD:.4f}")
        print("Decision:", decision)