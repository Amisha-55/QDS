import hashlib

from qds_signature import message_to_bits


VALID_BASES = {"Z", "X", "Y"}


def verify_signature(signature, message, threshold=0.95):
    """
    Verify a teleportation-based quantum signature simulation.

    Verification checks:

    1. Recalculate the SHA-256 fingerprint of the trusted message.
    2. Compare it with the classical integrity fingerprint.
    3. Convert the trusted message into bits independently.
    4. Check that the quantum signature contains the expected
       number of message bits.
    5. Check every quantum signature element:
         - message bit
         - measurement basis
         - expected measurement outcome
         - measurement results
    6. Calculate the overall quantum measurement accuracy.
    7. Apply the statistical verification threshold.

    The message supplied to this function is treated as the
    trusted/original message.

    SHA-256 is used only as a classical integrity fingerprint.
    It is NOT used to select the quantum state.

    This is a simulation/prototype model, not a production
    cryptographic QDS implementation.
    """


    if not isinstance(signature, dict):
        raise TypeError("Signature must be a dictionary")

    if not isinstance(message, str):
        raise TypeError("Message must be a string")

    if not message:
        raise ValueError("Message cannot be empty")

    if not 0 <= threshold <= 1:
        raise ValueError(
            "Threshold must be between 0 and 1"
        )



    calculated_hash = hashlib.sha256(
        message.encode("utf-8")
    ).hexdigest()

    classical_integrity = signature.get(
        "classical_integrity",
        {}
    )

    received_hash = classical_integrity.get(
        "message_hash",
        ""
    )

    hash_valid = (
        calculated_hash == received_hash
    )

   

    message_bits = message_to_bits(message)

    quantum_signature = signature.get(
        "quantum_signature",
        {}
    )

    elements = quantum_signature.get(
        "elements",
        []
    )

    quantum_bit_count = quantum_signature.get(
        "quantum_bit_count",
        0
    )

    

    bit_count_valid = (
        isinstance(quantum_bit_count, int)
        and quantum_bit_count > 0
        and quantum_bit_count <= len(message_bits)
        and quantum_bit_count == len(elements)
    )

    expected_bits = message_bits[:quantum_bit_count]

   

    elements_valid = True

    total_shots = 0
    correct_shots = 0

    element_results = []

    if not bit_count_valid:

        elements_valid = False

    else:

        for index, element in enumerate(elements):

            if not isinstance(element, dict):
                elements_valid = False

                element_results.append({
                    "index": index,
                    "valid": False,
                    "reason": "Invalid quantum element"
                })

                continue

           

            expected_bit = expected_bits[index]

          

            received_bit = element.get(
                "bit",
                None
            )

            basis = element.get(
                "basis",
                "UNKNOWN"
            )

            expected_outcome = element.get(
                "expected_outcome",
                None
            )

            counts = element.get(
                "measurement_results",
                {}
            )

            

            bit_valid = (
                received_bit == expected_bit
            )

            

            basis_valid = (
                basis in VALID_BASES
            )

           

            outcome_valid = (
                expected_outcome == expected_bit
            )

           

            element_total_shots = sum(
                counts.values()
            ) if isinstance(counts, dict) else 0

            element_correct_shots = 0

            if (
                isinstance(counts, dict)
                and element_total_shots > 0
            ):

                for outcome, count in counts.items():

                    if not outcome:
                        continue

                    try:
                        bob_bit = int(outcome[0])
                    except (ValueError, TypeError):
                        continue

                    if bob_bit == expected_bit:
                        element_correct_shots += count

            

            if element_total_shots > 0:

                element_accuracy = (
                    element_correct_shots
                    / element_total_shots
                )

            else:

                element_accuracy = 0.0

            

            element_valid = (
                bit_valid
                and basis_valid
                and outcome_valid
                and element_total_shots > 0
                and element_accuracy >= threshold
            )

            if not element_valid:
                elements_valid = False

            total_shots += element_total_shots
            correct_shots += element_correct_shots

            element_results.append({
                "index": index,
                "expected_bit": expected_bit,
                "received_bit": received_bit,
                "basis": basis,
                "expected_outcome": expected_outcome,
                "bit_valid": bit_valid,
                "basis_valid": basis_valid,
                "outcome_valid": outcome_valid,
                "total_shots": element_total_shots,
                "correct_shots": element_correct_shots,
                "accuracy": element_accuracy,
                "valid": element_valid
            })

    

    if total_shots > 0:

        verification_accuracy = (
            correct_shots / total_shots
        )

    else:

        verification_accuracy = 0.0

    

    if (
        hash_valid
        and bit_count_valid
        and elements_valid
        and verification_accuracy >= threshold
    ):
        decision = "VALID"

    else:
        decision = "INVALID / SUSPICIOUS"

   

    return {
        "message_hash_valid": hash_valid,

        "calculated_message_hash": calculated_hash,

        "received_message_hash": received_hash,

        "quantum_bit_count": quantum_bit_count,

        "expected_message_bit_count": len(message_bits),

        "bit_count_valid": bit_count_valid,

        "quantum_elements_valid": elements_valid,

        "element_results": element_results,

        "total_shots": total_shots,

        "correct_shots": correct_shots,

        "verification_accuracy": verification_accuracy,

        "threshold": threshold,

        "decision": decision
    }





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

    print("\nSHA-256 Fingerprint Valid:")
    print(
        result["message_hash_valid"]
    )

    print("\nQuantum Bit Count:")
    print(
        result["quantum_bit_count"]
    )

    print("\nExpected Message Bit Count:")
    print(
        result["expected_message_bit_count"]
    )

    print("\nQuantum Elements Valid:")
    print(
        result["quantum_elements_valid"]
    )

    print("\nTotal Measurement Shots:")
    print(
        result["total_shots"]
    )

    print("\nCorrect Measurements:")
    print(
        result["correct_shots"]
    )

    print("\nVerification Accuracy:")
    print(
        f"{result['verification_accuracy'] * 100:.2f}%"
    )

    print("\nThreshold:")
    print(
        f"{result['threshold'] * 100:.2f}%"
    )

    print("\nVerification Decision:")
    print(
        result["decision"]
    )

    print(
        "\n========================================"
    )