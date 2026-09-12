from config import THRESHOLD, SHOTS


def detect_threat(error_rate, threshold=THRESHOLD):
    """
    Detect whether a quantum measurement result
    is within the legitimate error range.
    """

    if error_rate <= threshold:
        return "LEGITIMATE"
    else:
        return "SUSPICIOUS / ATTACK"


def calculate_error_rate(counts, shots):
    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    error_rate = probability_1

    return probability_0, probability_1, error_rate


if __name__ == "__main__":

    print("========================================")
    print("       STATISTICAL THREAT DETECTOR")
    print("========================================")

    shots = SHOTS

    # Example legitimate result
    legitimate_counts = {"0": 988, "1": 12}

    p0, p1, legitimate_error = calculate_error_rate(
        legitimate_counts,
        shots
    )

    legitimate_decision = detect_threat(legitimate_error)

    print("\nLEGITIMATE TEST")
    print("Measurement Results:", legitimate_counts)
    print(f"P(0): {p0:.3f}")
    print(f"P(1): {p1:.3f}")
    print(f"Error Rate: {legitimate_error:.3f}")
    print(f"Threshold: {THRESHOLD:.4f}")
    print("Decision:", legitimate_decision)


    # Example attack result
    attack_counts = {"0": 12, "1": 988}

    p0, p1, attack_error = calculate_error_rate(
        attack_counts,
        shots
    )

    attack_decision = detect_threat(attack_error)

    print("\nATTACK TEST")
    print("Measurement Results:", attack_counts)
    print(f"P(0): {p0:.3f}")
    print(f"P(1): {p1:.3f}")
    print(f"Error Rate: {attack_error:.3f}")
    print(f"Threshold: {THRESHOLD:.4f}")
    print("Decision:", attack_decision)