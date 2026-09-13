import hashlib

from qds_signature import message_to_state


def verify_signature(signature, message, threshold=0.95):
    """
    Verify a teleportation-based quantum signature simulation.

    Verification checks:

    1. Recalculate the SHA-256 hash from the trusted message.
    2. Independently derive the expected Pauli eigenstate.
    3. Check the received message hash.
    4. Check the received quantum-state metadata.
    5. Check the received measurement basis.
    6. Evaluate Bob's projective measurement results.
    7. Apply the statistical verification threshold.

    The message supplied to this function is treated as the
    trusted/original message and is NOT taken from the signature.

    This is a simulation/prototype model, not a production
    cryptographic QDS implementation.
    """

    # -----------------------------------------------
    # 0. Validate input
    # -----------------------------------------------

    if not isinstance(message, str):
        raise TypeError("Message must be a string")

    if not message:
        raise ValueError("Message cannot be empty")

    if not 0 <= threshold <= 1:
        raise ValueError(
            "Threshold must be between 0 and 1"
        )

    # -----------------------------------------------
    # 1. Recalculate message hash
    # -----------------------------------------------

    calculated_hash = hashlib.sha256(
        message.encode()
    ).hexdigest()

    received_hash = signature.get(
        "message_hash",
        ""
    )

    hash_valid = (
        calculated_hash == received_hash
    )

    # -----------------------------------------------
    # 2. Independently derive expected state
    # -----------------------------------------------

    expected_state = message_to_state(message)

    received_state = signature.get(
        "quantum_state",
        "UNKNOWN"
    )

    state_valid = (
        expected_state == received_state
    )

    # -----------------------------------------------
    # 3. Check measurement basis
    # -----------------------------------------------

    expected_basis = expected_state

    received_basis = signature.get(
        "measurement_basis",
        "UNKNOWN"
    )

    basis_valid = (
        expected_basis == received_basis
    )

    # -----------------------------------------------
    # 4. Obtain measurement results
    # -----------------------------------------------

    counts = signature.get(
        "measurement_results",
        {}
    )

    total_shots = sum(
        counts.values()
    )

    if total_shots == 0:

        return {
            "expected_state": expected_state,
            "received_state": received_state,
            "expected_basis": expected_basis,
            "received_basis": received_basis,
            "hash_valid": hash_valid,
            "state_valid": state_valid,
            "basis_valid": basis_valid,
            "total_shots": 0,
            "correct_shots": 0,
            "verification_accuracy": 0.0,
            "threshold": threshold,
            "decision": "INVALID / SUSPICIOUS"
        }

    # -----------------------------------------------
    # 5. Evaluate Bob's projective measurement
    #
    # All three states are +1 eigenstates.
    #
    # After measurement in the matching basis:
    #
    # Z -> expected bit 0
    # X -> expected bit 0
    # Y -> expected bit 0
    #
    # Qiskit displays classical bits as:
    #
    #     c2 c1 c0
    #
    # Bob's measurement is c2 = leftmost bit.
    # -----------------------------------------------

    expected_bit = 0
    correct_shots = 0

    for outcome, count in counts.items():

        if not outcome:
            continue

        bob_bit = int(
            outcome[0]
        )

        if bob_bit == expected_bit:
            correct_shots += count

    # -----------------------------------------------
    # 6. Calculate verification accuracy
    # -----------------------------------------------

    verification_accuracy = (
        correct_shots / total_shots
    )

    # -----------------------------------------------
    # 7. Final verification decision
    # -----------------------------------------------

    if (
        hash_valid
        and state_valid
        and basis_valid
        and verification_accuracy >= threshold
    ):
        decision = "VALID"
    else:
        decision = "INVALID / SUSPICIOUS"

    return {
        "expected_state": expected_state,
        "received_state": received_state,
        "expected_basis": expected_basis,
        "received_basis": received_basis,
        "hash_valid": hash_valid,
        "state_valid": state_valid,
        "basis_valid": basis_valid,
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

    signature = generate_signature(
        message
    )

    result = verify_signature(
        signature,
        message
    )

    print(
        "========================================"
    )
    print(
        "       QDS SIGNATURE VERIFICATION"
    )
    print(
        "========================================"
    )

    print("\nMessage:")
    print(message)

    print("\nExpected Quantum State:")
    print(result["expected_state"])

    print("\nReceived Quantum State:")
    print(result["received_state"])

    print("\nExpected Measurement Basis:")
    print(result["expected_basis"])

    print("\nReceived Measurement Basis:")
    print(result["received_basis"])

    print("\nHash Valid:")
    print(result["hash_valid"])

    print("\nState Valid:")
    print(result["state_valid"])

    print("\nBasis Valid:")
    print(result["basis_valid"])

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

    print(
        "\n========================================"
    )

