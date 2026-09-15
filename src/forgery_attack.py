from copy import deepcopy

from classical_signature import generate_key_pair
from secure_packet import (
    create_secure_packet,
    verify_secure_packet
)
from trusted_keys import register_public_key




MESSAGE = "SIH26141"
FORGED_MESSAGE = "FAKE-SIH26141"
SIGNER_ID = "Alice"


print("========================================")
print("        FORGERY ATTACK SIMULATION")
print("========================================")




print("\n[1] GENERATING LEGITIMATE SIGNER")

alice_private_key, alice_public_key = generate_key_pair()

print("Signer ID:")
print(SIGNER_ID)

print("Ed25519 key pair generated.")




print("\n[2] REGISTERING ALICE'S TRUSTED PUBLIC KEY")

try:

    register_public_key(
        SIGNER_ID,
        alice_public_key
    )

    print("Alice's public key is trusted.")

except ValueError as error:

    print(
        f"Key registration error: {error}"
    )

    print(
        "\nIf Alice already has a different key "
        "registered, remove the old prototype "
        "registry entry before running this test."
    )

    raise




print("\n[3] CREATING LEGITIMATE SECURE PACKET")

legitimate_packet = create_secure_packet(
    MESSAGE,
    alice_private_key,
    SIGNER_ID
)

print("Original Message:")
print(MESSAGE)

print("Signer ID:")
print(
    legitimate_packet["payload"]["signer_id"]
)




print("\n[4] VERIFYING LEGITIMATE PACKET")

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




print("\n[5] CREATING FORGED PACKET")

forged_packet = deepcopy(
    legitimate_packet
)



forged_packet["payload"]["message"] = FORGED_MESSAGE

print("Original Message:")
print(MESSAGE)

print("Attacker's Modified Message:")
print(FORGED_MESSAGE)

print(
    "\nAttacker did NOT regenerate the Ed25519 "
    "signature."
)




print("\n[6] VERIFYING FORGED PACKET")

forged_result = verify_secure_packet(
    forged_packet,
    alice_public_key
)

print("\nEd25519 Verification:")
print(
    "VALID"
    if forged_result["classical_signature_valid"]
    else "INVALID"
)

print("\nQuantum Verification:")

if "decision" in forged_result["qds_result"]:
    print(
        forged_result["qds_result"]["decision"]
    )
else:
    print("NOT VERIFIED")

print("\nFinal Decision:")
print(
    forged_result["final_decision"]
)





ed25519_failed = not (
    forged_result["classical_signature_valid"]
)

final_packet_rejected = (
    forged_result["final_decision"]
    == "INVALID / SUSPICIOUS"
)




if (
    ed25519_failed
    and final_packet_rejected
):

    final_decision = (
        "FORGERY ATTACK DETECTED"
    )

else:

    final_decision = (
        "FORGERY ATTACK NOT DETECTED"
    )




print("\n========================================")
print("             ATTACK RESULT")
print("========================================")

print("\nAttack Type:")
print("Message Forgery")

print("\nOriginal Message:")
print(MESSAGE)

print("\nForged Message:")
print(FORGED_MESSAGE)

print("\nEd25519 Protection:")
print(
    "PASSED - Tampering was detected"
    if ed25519_failed
    else "FAILED - Tampering was not detected"
)

print("\nFinal Result:")
print(final_decision)

print("\n========================================")