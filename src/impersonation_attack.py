from qds_signature import generate_signature
from qds_verify import verify_signature
from copy import deepcopy


# --------------------------------------------------
# IMPERSONATION ATTACK SIMULATION
# --------------------------------------------------

message = "SIH26141"

print("========================================")
print("     IMPERSONATION ATTACK SIMULATION")
print("========================================")


# --------------------------------------------------
# 1. LEGITIMATE SIGNER
# --------------------------------------------------

legitimate_signature = generate_signature(message)

print("\n[1] LEGITIMATE SIGNER")

legitimate_result = verify_signature(legitimate_signature)

print("Quantum State:")
print(legitimate_result["expected_state"])

print("Verification Accuracy:")
print(f"{legitimate_result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(legitimate_result["decision"])


# --------------------------------------------------
# 2. ATTACKER IMPERSONATES SIGNER
# --------------------------------------------------

impersonated_signature = deepcopy(legitimate_signature)

# Attacker claims a different quantum state
if impersonated_signature["quantum_state"] == "|0>":
    impersonated_signature["quantum_state"] = "|1>"
else:
    impersonated_signature["quantum_state"] = "|0>"


print("\n[2] IMPERSONATION ATTACK")

print("Attacker's Claimed Quantum State:")
print(impersonated_signature["quantum_state"])


# --------------------------------------------------
# VERIFY IMPERSONATED SIGNATURE
# --------------------------------------------------

impersonated_result = verify_signature(impersonated_signature)

print("\nVerification Accuracy:")
print(f"{impersonated_result['verification_accuracy'] * 100:.2f}%")

print("Decision:")
print(impersonated_result["decision"])


# --------------------------------------------------
# FINAL RESULT
# --------------------------------------------------

print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

if impersonated_result["decision"] != "VALID":
    print("IMPERSONATION ATTACK DETECTED")
else:
    print("IMPERSONATION ATTACK NOT DETECTED")