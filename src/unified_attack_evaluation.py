from copy import deepcopy

from classical_signature import generate_key_pair
from trusted_keys import register_public_key, get_public_key
from secure_packet import create_secure_packet, verify_secure_packet


print("========================================")
print("       QDS + CLASSICAL SIGNATURE")
print("========================================")


print("\n[1] SENDER KEY GENERATION")

sender_private_key, sender_public_key = generate_key_pair()

register_public_key(
    "SENDER",
    sender_public_key
)

print("Private key: Generated")
print("Public key: Generated")
print("Public key registered as trusted.")


message = "Hello Receiver"

packet = create_secure_packet(
    message,
    sender_private_key,
    "SENDER"
)

print("\n[2] SENDER SENDS MESSAGE")

print("Message:")
print(message)

print("\nSecure packet created.")


print("\n[3] RECEIVER LOADS TRUSTED PUBLIC KEY")

sender_trusted_public_key = get_public_key(
    "SENDER"
)

print("Trusted public key loaded for SENDER.")


result = verify_secure_packet(
    packet,
    sender_trusted_public_key
)

print("\n[4] RECEIVER VERIFICATION")

print(
    "Classical Signature:",
    result["classical_signature_valid"]
)

print(
    "QDS Verification:",
    result["qds_result"]["decision"]
)

print(
    "FINAL DECISION:",
    result["final_decision"]
)


tampered_packet = deepcopy(packet)

tampered_packet["payload"]["message"] = (
    "Hello Receiver!!!"
)

print("\n[5] ATTACKER MODIFIES MESSAGE")

print("Original Message:")
print(
    packet["payload"]["message"]
)

print("Tampered Message:")
print(
    tampered_packet["payload"]["message"]
)

tampered_result = verify_secure_packet(
    tampered_packet,
    sender_trusted_public_key
)

print("\nClassical Signature:")
print(
    tampered_result["classical_signature_valid"]
)

print(
    "FINAL DECISION:",
    tampered_result["final_decision"]
)


quantum_attack_packet = deepcopy(packet)

qds_signature = (
    quantum_attack_packet["payload"]["qds_signature"]
)

quantum_signature = (
    qds_signature["quantum_signature"]
)

elements = quantum_signature["elements"]


if not elements:
    raise ValueError(
        "QDS signature contains no quantum elements."
    )

first_element = elements[0]

original_bit = first_element["bit"]

first_element["bit"] = 1 - original_bit

first_element["expected_outcome"] = (
    1 - first_element["expected_outcome"]
)


print("\n[6] ATTACKER MODIFIES QDS DATA")

print(
    "Original quantum bit:",
    original_bit
)

print(
    "Modified quantum bit:",
    first_element["bit"]
)

print("Quantum signature element modified.")


quantum_attack_result = verify_secure_packet(
    quantum_attack_packet,
    sender_trusted_public_key
)

print("\nClassical Signature:")
print(
    quantum_attack_result[
        "classical_signature_valid"
    ]
)

print(
    "FINAL DECISION:",
    quantum_attack_result[
        "final_decision"
    ]
)


print("\n========================================")
print("             SECURITY SUMMARY")
print("========================================")


print("\nLegitimate Packet:")

print(
    "Classical Signature:",
    result["classical_signature_valid"]
)

print(
    "QDS Verification:",
    result["qds_result"]["decision"]
)

print(
    "Final Decision:",
    result["final_decision"]
)


print("\nMessage Tampering:")

print(
    "Classical Signature:",
    tampered_result[
        "classical_signature_valid"
    ]
)

print(
    "Final Decision:",
    tampered_result[
        "final_decision"
    ]
)


print("\nQuantum Data Tampering:")

print(
    "Classical Signature:",
    quantum_attack_result[
        "classical_signature_valid"
    ]
)

print(
    "Final Decision:",
    quantum_attack_result[
        "final_decision"
    ]
)


print("\n========================================")
print("              TEST COMPLETE")
print("========================================")