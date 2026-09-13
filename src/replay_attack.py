from qds_signature import generate_signature
from qds_verify import verify_signature
from datetime import datetime
from copy import deepcopy
import uuid


# ----------------------------------------
# REPLAY REGISTRY
# ----------------------------------------

USED_SIGNATURES = set()


def check_replay(signature_id):
    """
    Check whether a signature has already been used.

    Returns:
        True  -> replay detected
        False -> signature is new
    """
    if signature_id in USED_SIGNATURES:
        return True

    USED_SIGNATURES.add(signature_id)
    return False


# ----------------------------------------
# MAIN REPLAY ATTACK SIMULATION
# ----------------------------------------

message = "SIH26141"

print("========================================")
print("       REPLAY ATTACK SIMULATION")
print("========================================")


# ----------------------------------------
# 1. ORIGINAL SIGNATURE
# ----------------------------------------

signature = generate_signature(message)

signature["signature_id"] = str(uuid.uuid4())
signature["timestamp"] = datetime.now().isoformat()


print("\n[1] ORIGINAL SIGNATURE")

print("Signature ID:")
print(signature["signature_id"])

print("Timestamp:")
print(signature["timestamp"])


# Quantum verification
result = verify_signature(
    signature,
    message
)

print("\nQuantum Verification:")
print(f"Verification Accuracy: "
      f"{result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(result["decision"])


# ----------------------------------------
# ACCEPT ORIGINAL SIGNATURE
# ----------------------------------------

if result["decision"] == "VALID":

    replay_detected = check_replay(
        signature["signature_id"]
    )

    if not replay_detected:
        print("\nSignature accepted.")
        print("Signature ID registered in replay registry.")
    else:
        print("\nUnexpected replay detected.")


# ----------------------------------------
# 2. REPLAY ATTACK
# ----------------------------------------

replayed_signature = deepcopy(signature)

print("\n[2] REPLAY ATTACK")

print("Replayed Signature ID:")
print(replayed_signature["signature_id"])

print("Same Signature ID:")
print(
    replayed_signature["signature_id"]
    == signature["signature_id"]
)


# Quantum verification still succeeds because
# the signature itself is cryptographically valid.
replay_result = verify_signature(
    replayed_signature,
    message
)

print("\nQuantum Verification:")
print(f"Verification Accuracy: "
      f"{replay_result['verification_accuracy'] * 100:.2f}%")

print("Cryptographic Decision:")
print(replay_result["decision"])


# ----------------------------------------
# REPLAY DETECTION
# ----------------------------------------

replay_detected = check_replay(
    replayed_signature["signature_id"]
)


if replay_detected:
    replay_decision = "REPLAY ATTACK DETECTED"
else:
    replay_decision = "NO REPLAY DETECTED"


print("\nReplay Registry Check:")
print(replay_decision)


# ----------------------------------------
# FINAL RESULT
# ----------------------------------------

print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

print(replay_decision)