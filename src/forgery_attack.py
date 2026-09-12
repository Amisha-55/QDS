from qds_signature import generate_signature
from qds_verify import verify_signature
from copy import deepcopy


# --------------------------------------------------
# GENERATE LEGITIMATE SIGNATURE
# --------------------------------------------------

message = "SIH26141"

legitimate_signature = generate_signature(message)


print("========================================")
print("       FORGERY ATTACK SIMULATION")
print("========================================")


# --------------------------------------------------
# VERIFY LEGITIMATE SIGNATURE
# --------------------------------------------------

print("\n[1] LEGITIMATE SIGNATURE")

legitimate_result = verify_signature(legitimate_signature)

print("Expected State:")
print(legitimate_result["expected_state"])

print("Verification Accuracy:")
print(f"{legitimate_result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(legitimate_result["decision"])


# --------------------------------------------------
# CREATE FORGED SIGNATURE
# --------------------------------------------------

forged_signature = deepcopy(legitimate_signature)

# Attacker changes the claimed quantum state
if forged_signature["quantum_state"] == "|0>":
    forged_signature["quantum_state"] = "|1>"
else:
    forged_signature["quantum_state"] = "|0>"


# --------------------------------------------------
# VERIFY FORGED SIGNATURE
# --------------------------------------------------

print("\n[2] FORGED SIGNATURE")

forged_result = verify_signature(forged_signature)

print("Claimed State:")
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