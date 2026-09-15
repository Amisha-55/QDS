from copy import deepcopy
from datetime import datetime, timezone
import uuid
import base64

from classical_signature import generate_key_pair, sign_data
from secure_packet import (
    create_secure_packet,
    verify_secure_packet,
    canonical_json,
)
from trusted_keys import register_public_key


# ==================================================
# REPLAY REGISTRY
# ==================================================

USED_SIGNATURES = set()


def check_replay(signature_id):
    """
    Check whether a signature ID has already been used.

    Returns:
        True  -> replay detected
        False -> signature is new and registered
    """

    if not isinstance(signature_id, str):
        raise TypeError(
            "Signature ID must be a string"
        )

    if not signature_id:
        raise ValueError(
            "Signature ID cannot be empty"
        )

    if signature_id in USED_SIGNATURES:
        return True

    USED_SIGNATURES.add(signature_id)

    return False


def reset_replay_registry():
    """Clear the replay registry."""
    USED_SIGNATURES.clear()


def simulate_replay(packet):
    """
    Simulate a replay attack by re-sending an exact copy
    of a previously accepted packet (same signature_id).

    Args:
        packet: The original accepted packet.

    Returns:
        A deep copy of the packet (identical signature_id).
    """
    return deepcopy(packet)


def build_replay_packet(message, private_key, signer_id):
    """
    Create a secure packet with replay-protection metadata
    (signature_id + timestamp) and re-sign it.

    Args:
        message: The message to sign.
        private_key: The signer's Ed25519 private key.
        signer_id: The signer's identity string.

    Returns:
        A secure packet with signature_id and timestamp fields,
        properly signed.
    """
    packet = create_secure_packet(
        message,
        private_key,
        signer_id,
    )

    signature_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    packet["payload"]["signature_id"] = signature_id
    packet["payload"]["timestamp"] = timestamp

    # Re-sign to cover the new fields
    payload_bytes = canonical_json(packet["payload"])
    new_sig = sign_data(private_key, payload_bytes)
    packet["classical_signature"] = base64.b64encode(
        new_sig
    ).decode("ascii")

    return packet


# ==================================================
# MAIN REPLAY ATTACK SIMULATION
# ==================================================

MESSAGE = "SIH26141"
SIGNER_ID = "Alice"


def run_replay_attack():
    """Run the full replay attack simulation (standalone demo)."""

    print("========================================")
    print("          REPLAY ATTACK SIMULATION")
    print("========================================")

    # ==================================================
    # 1. GENERATE ALICE'S KEY PAIR
    # ==================================================

    print("\n[1] GENERATING ALICE'S KEY PAIR")

    alice_private_key, alice_public_key = generate_key_pair()

    print(
        "Alice's Ed25519 key pair generated."
    )

    # ==================================================
    # 2. REGISTER ALICE'S TRUSTED PUBLIC KEY
    # ==================================================

    print("\n[2] REGISTERING ALICE'S TRUSTED PUBLIC KEY")

    try:

        register_public_key(
            SIGNER_ID,
            alice_public_key
        )

        print(
            "Alice's public key is trusted."
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

    # ==================================================
    # 3. CREATE ORIGINAL SECURE PACKET
    # ==================================================

    print("\n[3] CREATING ORIGINAL SECURE PACKET")

    original_packet = build_replay_packet(
        MESSAGE,
        alice_private_key,
        SIGNER_ID
    )

    signature_id = original_packet["payload"]["signature_id"]
    timestamp = original_packet["payload"]["timestamp"]

    print("\nSignature ID:")
    print(signature_id)

    print("\nTimestamp:")
    print(timestamp)

    print("\nMessage:")
    print(MESSAGE)

    print("\nSigner ID:")
    print(SIGNER_ID)

    # ==================================================
    # 4. VERIFY ORIGINAL PACKET
    # ==================================================

    print("\n[4] VERIFYING ORIGINAL PACKET")

    original_result = verify_secure_packet(
        original_packet,
        alice_public_key
    )

    print("\nEd25519 Verification:")
    print(
        "VALID"
        if original_result["classical_signature_valid"]
        else "INVALID"
    )

    print("\nQuantum Verification:")
    print(
        original_result["qds_result"]["decision"]
    )

    print("\nFinal Decision:")
    print(
        original_result["final_decision"]
    )

    # ==================================================
    # 5. ACCEPT ORIGINAL PACKET
    # ==================================================

    print("\n[5] RECEIVER ACCEPTS ORIGINAL PACKET")

    if original_result["final_decision"] == "TRUSTED":

        replay_detected = check_replay(
            original_packet["payload"]["signature_id"]
        )

        if not replay_detected:

            original_accepted = True

            print(
                "Signature accepted."
            )

            print(
                "Signature ID registered "
                "in replay registry."
            )

        else:

            original_accepted = False

            print(
                "Unexpected replay detected."
            )

    else:

        original_accepted = False

        print(
            "Original packet rejected."
        )

    # ==================================================
    # 6. CREATE REPLAYED PACKET
    # ==================================================

    print("\n[6] CREATING REPLAY ATTACK")

    replayed_packet = simulate_replay(
        original_packet
    )

    print("\nOriginal Signature ID:")
    print(
        original_packet["payload"]["signature_id"]
    )

    print("\nReplayed Signature ID:")
    print(
        replayed_packet["payload"]["signature_id"]
    )

    print("\nSame Signature ID:")

    print(
        replayed_packet["payload"]["signature_id"]
        ==
        original_packet["payload"]["signature_id"]
    )

    # ==================================================
    # 7. VERIFY REPLAYED PACKET
    # ==================================================

    print("\n[7] VERIFYING REPLAYED PACKET")

    replay_result = verify_secure_packet(
        replayed_packet,
        alice_public_key
    )

    print("\nEd25519 Verification:")
    print(
        "VALID"
        if replay_result["classical_signature_valid"]
        else "INVALID"
    )

    print("\nQuantum Verification:")
    print(
        replay_result["qds_result"]["decision"]
    )

    print("\nCryptographic Decision:")
    print(
        replay_result["final_decision"]
    )

    # ==================================================
    # 8. CHECK REPLAY REGISTRY
    # ==================================================

    print("\n[8] CHECKING REPLAY REGISTRY")

    replay_detected = check_replay(
        replayed_packet["payload"]["signature_id"]
    )

    print("\nSignature ID Already Used:")

    print(
        "YES"
        if replay_detected
        else "NO"
    )

    # ==================================================
    # 9. FINAL REPLAY DECISION
    # ==================================================

    if (
        replay_detected
        and replay_result["final_decision"]
        == "TRUSTED"
    ):

        final_decision = (
            "REPLAY ATTACK DETECTED"
        )

    elif replay_detected:

        final_decision = (
            "REPLAY ATTACK DETECTED"
        )

    else:

        final_decision = (
            "NO REPLAY DETECTED"
        )

    # ==================================================
    # 10. DISPLAY FINAL RESULT
    # ==================================================

    print("\n========================================")
    print("             ATTACK RESULT")
    print("========================================")

    print("\nAttack Type:")
    print("Replay Attack")

    print("\nOriginal Signature ID:")
    print(
        original_packet["payload"]["signature_id"]
    )

    print("\nReplayed Signature ID:")
    print(
        replayed_packet["payload"]["signature_id"]
    )

    print("\nOriginal Packet Accepted:")
    print(
        "YES"
        if original_accepted
        else "NO"
    )

    print("\nReplayed Packet Cryptographically Valid:")
    print(
        "YES"
        if replay_result["final_decision"] == "TRUSTED"
        else "NO"
    )

    print("\nReplay Registry Detection:")
    print(
        "DETECTED"
        if replay_detected
        else "NOT DETECTED"
    )

    print("\nFinal Result:")
    print(final_decision)

    print("\n========================================")


if __name__ == "__main__":
    run_replay_attack()