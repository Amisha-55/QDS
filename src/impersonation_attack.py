from classical_signature import generate_key_pair
from secure_packet import (
    create_secure_packet,
    verify_secure_packet
)
from trusted_keys import register_public_key


MESSAGE = "SIH26141"

ALICE_ID = "Alice"
ATTACKER_ID = "Attacker"


def simulate_impersonation(message, claimed_signer_id):
    """
    Simulate an impersonation attack: attacker generates their own
    key pair but claims to be the legitimate signer.

    Args:
        message: The message to sign.
        claimed_signer_id: The signer ID the attacker claims to be.

    Returns:
        The impersonated packet signed with the attacker's private key.
    """
    attacker_private, _attacker_public = generate_key_pair()
    packet = create_secure_packet(
        message,
        attacker_private,
        claimed_signer_id,
    )
    return packet


def run_impersonation_attack():
    """Run the full impersonation attack simulation (standalone demo)."""

    print("========================================")
    print("      IMPERSONATION ATTACK SIMULATION")
    print("========================================")

    # ==================================================
    # 1. GENERATE ALICE'S KEY PAIR
    # ==================================================

    print("\n[1] GENERATING ALICE'S KEY PAIR")

    alice_private_key, alice_public_key = generate_key_pair()

    print("Alice's Ed25519 key pair generated.")

    print("\n[2] REGISTERING ALICE'S TRUSTED PUBLIC KEY")

    try:

        register_public_key(
            ALICE_ID,
            alice_public_key
        )

        print(
            "Alice's public key is registered as trusted."
        )

    except ValueError as error:

        print(
            f"Key registration error: {error}"
        )

        print(
            "\nIf Alice already has a different key "
            "registered, remove the old prototype "
            "Alice entry from keys/public_keys.json "
            "before running this test."
        )

        raise

    print("\n[3] GENERATING ATTACKER'S KEY PAIR")

    attacker_private_key, attacker_public_key = (
        generate_key_pair()
    )

    print(
        "Attacker's Ed25519 key pair generated."
    )

    print(
        "\nImportant:"
    )

    print(
        "The attacker has their own private key,"
        " but does NOT have Alice's private key."
    )

    print("\n[4] CREATING LEGITIMATE ALICE PACKET")

    legitimate_packet = create_secure_packet(
        MESSAGE,
        alice_private_key,
        ALICE_ID
    )

    print("Signer ID:")
    print(
        legitimate_packet["payload"]["signer_id"]
    )

    print("Message:")
    print(
        legitimate_packet["payload"]["message"]
    )

    print("\n[5] VERIFYING LEGITIMATE ALICE PACKET")

    legitimate_result = verify_secure_packet(
        legitimate_packet,
        alice_public_key
    )

    print("\nEd25519 Verification:")
    print(
        "VALID"
        if legitimate_result["classical_signature_valid"]
        else "INVALID"
    )

    print("\nQuantum Verification:")
    print(
        legitimate_result["qds_result"]["decision"]
    )

    print("\nFinal Decision:")
    print(
        legitimate_result["final_decision"]
    )

    print("\n[6] CREATING IMPERSONATION ATTACK")

    print(
        "Attacker claims to be:",
        ALICE_ID
    )

    print(
        "Attacker actually owns:",
        ATTACKER_ID
    )

    impersonated_packet = create_secure_packet(
        MESSAGE,
        attacker_private_key,
        ALICE_ID
    )

    print("\nClaimed Signer ID:")
    print(
        impersonated_packet["payload"]["signer_id"]
    )

    print("\nActual Signing Key:")
    print(
        "ATTACKER'S PRIVATE KEY"
    )

    print("\n[7] RECEIVER USES ALICE'S TRUSTED PUBLIC KEY")

    print(
        "The receiver does NOT trust the public key "
        "provided by the attacker."
    )

    print(
        "The receiver uses Alice's registered "
        "trusted public key."
    )

    print("\n[8] VERIFYING IMPERSONATED PACKET")

    impersonated_result = verify_secure_packet(
        impersonated_packet,
        alice_public_key
    )

    print("\nEd25519 Verification:")
    print(
        "VALID"
        if impersonated_result["classical_signature_valid"]
        else "INVALID"
    )

    print("\nQuantum Verification:")

    if "decision" in impersonated_result["qds_result"]:

        print(
            impersonated_result["qds_result"]["decision"]
        )

    else:

        print("NOT VERIFIED")

    print("\nFinal Decision:")
    print(
        impersonated_result["final_decision"]
    )

    ed25519_failed = not (
        impersonated_result[
            "classical_signature_valid"
        ]
    )

    packet_rejected = (
        impersonated_result["final_decision"]
        == "INVALID / SUSPICIOUS"
    )

    if (
        ed25519_failed
        and packet_rejected
    ):

        final_decision = (
            "IMPERSONATION ATTACK DETECTED"
        )

    else:

        final_decision = (
            "IMPERSONATION ATTACK NOT DETECTED"
        )

    print("\n========================================")
    print("             ATTACK RESULT")
    print("========================================")

    print("\nAttack Type:")
    print("Signer Impersonation")

    print("\nClaimed Identity:")
    print(ALICE_ID)

    print("\nActual Signing Entity:")
    print(ATTACKER_ID)

    print("\nAlice's Trusted Public Key:")
    print("USED BY RECEIVER")

    print("\nAttacker's Private Key:")
    print("USED TO CREATE FORGED PACKET")

    print("\nEd25519 Protection:")

    if ed25519_failed:

        print(
            "PASSED - Impersonation was detected"
        )

    else:

        print(
            "FAILED - Impersonation was not detected"
        )

    print("\nFinal Result:")
    print(final_decision)

    print("\n========================================")


if __name__ == "__main__":
    run_impersonation_attack()