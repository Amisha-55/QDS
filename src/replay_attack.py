from qds_signature import generate_signature
from qds_verify import verify_signature
from datetime import datetime
from copy import deepcopy
import uuid


# --------------------------------------------------
# REPLAY ATTACK SIMULATION
# --------------------------------------------------

message = "SIH26141"

print("========================================")
print("         REPLAY ATTACK SIMULATION")
print("========================================")


# --------------------------------------------------
# 1. GENERATE ORIGINAL LEGITIMATE SIGNATURE
# --------------------------------------------------

signature = generate_signature(message)

signature["signature_id"] = str(uuid.uuid4())
signature["timestamp"] = datetime.now().isoformat()
signature["used"] = False


print("\n[1] ORIGINAL SIGNATURE")

print("Signature ID:")
print(signature["signature_id"])

print("Timestamp:")
print(signature["timestamp"])


# --------------------------------------------------
# 2. VERIFY ORIGINAL SIGNATURE
# --------------------------------------------------

result = verify_signature(
    signature,
    message
)

print("\nVerification Accuracy:")
print(f"{result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(result["decision"])


# --------------------------------------------------
# 3. ACCEPT ORIGINAL SIGNATURE
# --------------------------------------------------

if result["decision"] == "VALID":

    signature["used"] = True

    print("\nOriginal signature accepted.")
    print("Signature marked as USED.")


# --------------------------------------------------
# 4. ATTACKER REPLAYS SAME SIGNATURE
# --------------------------------------------------

replayed_signature = deepcopy(signature)

print("\n[2] REPLAY ATTACK")

print("Replayed Signature ID:")
print(replayed_signature["signature_id"])

print("Original Signature Already Used:")
print(replayed_signature["used"])


# --------------------------------------------------
# 5. VERIFY REPLAY
# --------------------------------------------------

replay_result = verify_signature(
    replayed_signature,
    message
)

print("\nCryptographic Verification:")
print(replay_result["decision"])


# --------------------------------------------------
# 6. REPLAY DETECTION
# --------------------------------------------------

if replayed_signature["used"]:

    replay_decision = "REPLAY ATTACK DETECTED"

else:

    replay_decision = "NO REPLAY DETECTED"


print("\nReplay Detection Decision:")
print(replay_decision)


# --------------------------------------------------
# FINAL RESULT
# --------------------------------------------------

print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

if replay_decision == "REPLAY ATTACK DETECTED":
    print("REPLAY ATTACK DETECTED")
else:
    print("REPLAY ATTACK NOT DETECTED")