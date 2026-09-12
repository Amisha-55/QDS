from qds_signature import generate_signature


def verify_signature(signature, threshold=0.95):
    """
    Verify a quantum signature using the measurement results.

    threshold:
        Minimum verification accuracy required for acceptance.
        This is currently a prototype value and will later be
        calibrated from legitimate/attack simulation data.
    """

    expected_state = signature["quantum_state"]
    expected_bit = int(expected_state[1])

    counts = signature["measurement_results"]

    total_shots = sum(counts.values())

    correct_shots = 0

    for outcome, count in counts.items():

        # Qiskit returns classical bits as c2 c1 c0.
        # Bob's final measurement is stored in c2,
        # therefore it is the LEFTMOST bit.
        bob_bit = int(outcome[0])

        if bob_bit == expected_bit:
            correct_shots += count

    verification_accuracy = correct_shots / total_shots

    if verification_accuracy >= threshold:
        decision = "VALID"
    else:
        decision = "INVALID / SUSPICIOUS"

    return {
        "expected_state": expected_state,
        "total_shots": total_shots,
        "correct_shots": correct_shots,
        "verification_accuracy": verification_accuracy,
        "threshold": threshold,
        "decision": decision
    }


# --------------------------------------------------
# TEST LEGITIMATE SIGNATURE
# --------------------------------------------------

message = "SIH26141"

signature = generate_signature(message)

result = verify_signature(signature)

print("===== QDS SIGNATURE VERIFICATION =====")

print("\nMessage:")
print(signature["message"])

print("\nExpected Quantum State:")
print(result["expected_state"])

print("\nTotal Measurement Shots:")
print(result["total_shots"])

print("\nCorrect Measurements:")
print(result["correct_shots"])

print("\nVerification Accuracy:")
print(f"{result['verification_accuracy'] * 100:.2f}%")

print("\nThreshold:")
print(f"{result['threshold'] * 100:.2f}%")

print("\nVerification Decision:")
print(result["decision"])