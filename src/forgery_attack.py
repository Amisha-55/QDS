from qds_signature import generate_signature
from qds_verify import verify_signature
from copy import deepcopy
import hashlib
import uuid


message = "SIH26141"

print("========================================")
print("          FORGERY ATTACK SIMULATION")
print("========================================")


# ----------------------------------------
# 1. GENERATE LEGITIMATE SIGNATURE
# ----------------------------------------

legitimate_signature = generate_signature(message)

legitimate_signature["signature_id"] = str(uuid.uuid4())

# Create an integrity hash from important
# signature information.
legitimate_signature["integrity_hash"] = hashlib.sha256(
    (
        message
        + legitimate_signature["quantum_state"]
    ).encode()
).hexdigest()

print("\n[1] LEGITIMATE SIGNATURE")

print("Message:")
print(message)

print("Quantum State:")
print(legitimate_signature["quantum_state"])

print("Signature ID:")
print(legitimate_signature["signature_id"])

print("Integrity Hash:")
print(legitimate_signature["integrity_hash"])


legitimate_result = verify_signature(
    legitimate_signature,
    message
)

print("\nQuantum Verification:")
print(
    f"Verification Accuracy: "
    f"{legitimate_result['verification_accuracy'] * 100:.2f}%"
)

print("Decision:")
print(legitimate_result["decision"])


# ----------------------------------------
# 2. CREATE FORGED SIGNATURE
# ----------------------------------------

forged_signature = deepcopy(legitimate_signature)

# Attacker modifies the message associated
# with the signature.
forged_message = "FAKE-SIH26141"

print("\n[2] FORGED SIGNATURE")

print("Original Message:")
print(message)

print("Attacker's Modified Message:")
print(forged_message)

# Recalculate what the attacker claims to be
# the correct integrity hash.
forged_signature["integrity_hash"] = hashlib.sha256(
    (
        forged_message
        + forged_signature["quantum_state"]
    ).encode()
).hexdigest()

print("\nForged Integrity Hash:")
print(forged_signature["integrity_hash"])


# ----------------------------------------
# 3. VERIFY FORGED SIGNATURE
# ----------------------------------------

forged_result = verify_signature(
    forged_signature,
    message
)

print("\nQuantum Verification:")
print(
    f"Verification Accuracy: "
    f"{forged_result['verification_accuracy'] * 100:.2f}%"
)

print("Cryptographic Decision:")
print(forged_result["decision"])


# ----------------------------------------
# 4. INTEGRITY CHECK
# ----------------------------------------

expected_integrity_hash = hashlib.sha256(
    (
        message
        + forged_signature["quantum_state"]
    ).encode()
).hexdigest()

integrity_valid = (
    forged_signature["integrity_hash"]
    == expected_integrity_hash
)

print("\nIntegrity Verification:")
print(
    "VALID"
    if integrity_valid
    else "INTEGRITY CHECK FAILED"
)


# ----------------------------------------
# 5. FINAL FORGERY DECISION
# ----------------------------------------

if forged_result["decision"] != "VALID":
    final_decision = "FORGERY ATTACK DETECTED"

elif not integrity_valid:
    final_decision = "FORGERY ATTACK DETECTED"

elif forged_message != message:
    final_decision = "FORGERY ATTACK DETECTED"

else:
    final_decision = "FORGERY ATTACK NOT DETECTED"


print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

print(final_decision)