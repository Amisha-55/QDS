from qds_signature import generate_signature
from qds_verify import verify_signature
from copy import deepcopy
import uuid


# ----------------------------------------
# AUTHORIZED SIGNERS
# ----------------------------------------

AUTHORIZED_SIGNERS = {
    "Alice": "ALICE-SECRET-KEY"
}


def authenticate_signer(signer_id, credential):
    """
    Verify whether the supplied signer identity
    has the correct authentication credential.
    """
    expected_credential = AUTHORIZED_SIGNERS.get(signer_id)

    if expected_credential is None:
        return False

    return credential == expected_credential


# ----------------------------------------
# MAIN IMPERSONATION ATTACK SIMULATION
# ----------------------------------------

message = "SIH26141"

print("========================================")
print("     IMPERSONATION ATTACK SIMULATION")
print("========================================")


# ----------------------------------------
# 1. LEGITIMATE SIGNER
# ----------------------------------------

legitimate_signature = generate_signature(message)

legitimate_signature["signature_id"] = str(uuid.uuid4())
legitimate_signature["signer_id"] = "Alice"
legitimate_signature["credential"] = "ALICE-SECRET-KEY"


print("\n[1] LEGITIMATE SIGNER")

print("Signer ID:")
print(legitimate_signature["signer_id"])

print("Signature ID:")
print(legitimate_signature["signature_id"])


# Authentication
authenticated = authenticate_signer(
    legitimate_signature["signer_id"],
    legitimate_signature["credential"]
)

print("\nIdentity Authentication:")
print("AUTHENTICATED" if authenticated else "NOT AUTHENTICATED")


# Quantum verification
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
# 2. IMPERSONATION ATTACK
# ----------------------------------------

impersonated_signature = deepcopy(
    legitimate_signature
)

# Attacker claims to be Alice but does not possess
# Alice's authentication credential.
impersonated_signature["signer_id"] = "Alice"
impersonated_signature["credential"] = "ATTACKER-CREDENTIAL"


print("\n[2] IMPERSONATION ATTACK")

print("Claimed Signer ID:")
print(impersonated_signature["signer_id"])

print("Attacker Credential:")
print(impersonated_signature["credential"])


# Authentication check
attacker_authenticated = authenticate_signer(
    impersonated_signature["signer_id"],
    impersonated_signature["credential"]
)

print("\nIdentity Authentication:")
print(
    "AUTHENTICATED"
    if attacker_authenticated
    else "AUTHENTICATION FAILED"
)


# Quantum verification
impersonated_result = verify_signature(
    impersonated_signature,
    message
)

print("\nQuantum Verification:")
print(
    f"Verification Accuracy: "
    f"{impersonated_result['verification_accuracy'] * 100:.2f}%"
)

print("Cryptographic Decision:")
print(impersonated_result["decision"])


# ----------------------------------------
# FINAL IMPERSONATION DECISION
# ----------------------------------------

if (
    not attacker_authenticated
    and impersonated_result["decision"] == "VALID"
):
    final_decision = "IMPERSONATION ATTACK DETECTED"

elif not attacker_authenticated:
    final_decision = "IMPERSONATION ATTACK DETECTED"

else:
    final_decision = "NO IMPERSONATION DETECTED"


print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

print(final_decision)

