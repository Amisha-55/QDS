from qds_signature import generate_signature
from qds_verify import verify_signature
from copy import deepcopy


# --------------------------------------------------
# FORGERY ATTACK SIMULATION
# --------------------------------------------------

message = "SIH26141"

legitimate_signature = generate_signature(message)

print("========================================")
print("       FORGERY ATTACK SIMULATION")
print("========================================")


# --------------------------------------------------
# 1. VERIFY LEGITIMATE SIGNATURE
# --------------------------------------------------

print("\n[1] LEGITIMATE SIGNATURE")

legitimate_result = verify_signature(
    legitimate_signature,
    message
)

print("Expected State:")
print(legitimate_result["expected_state"])

print("Verification Accuracy:")
print(f"{legitimate_result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(legitimate_result["decision"])


# --------------------------------------------------
# 2. CREATE FORGED SIGNATURE
# --------------------------------------------------

forged_signature = deepcopy(legitimate_signature)

# Attacker changes the claimed quantum state
states = ["Z", "X", "Y"]

current_state = forged_signature["quantum_state"]

for state in states:
    if state != current_state:
        forged_signature["quantum_state"] = state
        break


# --------------------------------------------------
# 3. VERIFY FORGED SIGNATURE
# --------------------------------------------------

print("\n[2] FORGED SIGNATURE")

print("Attacker's Claimed State:")
print(forged_signature["quantum_state"])

forged_result = verify_signature(
    forged_signature,
    message
)

print("Expected State:")
print(forged_result["expected_state"])

print("Verification Accuracy:")
print(f"{forged_result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(forged_result["decision"])


# --------------------------------------------------
# FINAL RESULT
# --------------------------------------------------

print("\n========================================")
print("              ATTACK RESULT")
print("========================================")

if forged_result["decision"] != "VALID":
    print("FORGERY ATTACK DETECTED")
else:
    print("FORGERY ATTACK NOT DETECTED")