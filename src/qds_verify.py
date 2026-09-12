import hashlib

from qds_signature import message_to_state


def verify_signature(signature, message, threshold=0.95):
    """
    Verify a teleportation-based quantum signature simulation.

    The verifier:
    1. Recalculates the SHA-256 hash from the trusted message.
    2. Independently derives the expected Pauli eigenstate.
    3. Checks the received signature hash.
    4. Evaluates Bob's projective measurement results.
    5. Applies a statistical verification threshold.

    The message supplied to this function is treated as the
    trusted/original message and is NOT taken from the signature.
    """

    # -----------------------------------------------
    # 1. Recalculate message hash
    # -----------------------------------------------

    calculated_hash = hashlib.sha256(
        message.encode()
    ).hexdigest()

    received_hash = signature["message_hash"]

    hash_valid = (
        calculated_hash == received_hash
    )

    # -----------------------------------------------
    # 2. Independently derive expected state
    # -----------------------------------------------

    expected_state = message_to_state(message)

    # -----------------------------------------------
    # 3. Obtain received measurement results
    # -----------------------------------------------

    counts = signature["measurement_results"]

    total_shots = sum(counts.values())

    if total_shots == 0:
        return {
            "expected_state": expected_state,
            "received_state": signature.get(
                "quantum_state",
                "UNKNOWN"
            ),
            "hash_valid": hash_valid,
            "total_shots": 0,
            "correct_shots": 0,
            "verification_accuracy": 0.0,
            "threshold": threshold,
            "decision": "INVALID / SUSPICIOUS"
        }

    # -----------------------------------------------
    # 4. Evaluate Bob's projective measurement
    #
    # All three states are +1 eigenstates.
    #
    # After the correct basis rotation:
    #
    # Z -> expected measurement 0
    # X -> expected measurement 0
    # Y -> expected measurement 0
    #
    # Qiskit returns classical bits as c2 c1 c0.
    # Bob's measurement is c2 = leftmost bit.
    # -----------------------------------------------

    expected_bit = 0
    correct_shots = 0

    for outcome, count in counts.items():

        bob_bit = int(outcome[0])

        if bob_bit == expected_bit:
            correct_shots += count

    # -----------------------------------------------
    # 5. Calculate verification accuracy
    # -----------------------------------------------

    verification_accuracy = (
        correct_shots / total_shots
    )

    # -----------------------------------------------
    # 6. Final verification decision
    # -----------------------------------------------

    if (
        hash_valid
        and expected_state == signature.get(
            "quantum_state",
            "UNKNOWN"
        )
        and verification_accuracy >= threshold
    ):
        decision = "VALID"
    else:
        decision = "INVALID / SUSPICIOUS"

    return {
        "expected_state": expected_state,
        "received_state": signature.get(
            "quantum_state",
            "UNKNOWN"
        ),
        "hash_valid": hash_valid,
        "total_shots": total_shots,
        "correct_shots": correct_shots,
        "verification_accuracy": verification_accuracy,
        "threshold": threshold,
        "decision": decision
    }


# --------------------------------------------------
# TEST LEGITIMATE SIGNATURE
# --------------------------------------------------

if __name__ == "__main__":

    from qds_signature import generate_signature

    message = "SIH26141"

    signature = generate_signature(message)

    result = verify_signature(
        signature,
        message
    )

    print("===== QDS SIGNATURE VERIFICATION =====")

    print("\nMessage:")
    print(message)

    print("\nExpected Quantum State:")
    print(result["expected_state"])

    print("\nReceived Quantum State:")
    print(result["received_state"])

    print("\nHash Valid:")
    print(result["hash_valid"])

    print("\nTotal Measurement Shots:")
    print(result["total_shots"])

    print("\nCorrect Measurements:")
    print(result["correct_shots"])

    print("\nVerification Accuracy:")
    print(
        f"{result['verification_accuracy'] * 100:.2f}%"
    )

    print("\nThreshold:")
    print(
        f"{result['threshold'] * 100:.2f}%"
    )

    print("\nVerification Decision:")
    print(result["decision"])

