from classical_signature import generate_key_pair

from trusted_keys import (
    register_public_key,
    get_public_key
)

from secure_packet import (
    create_secure_packet,
    verify_secure_packet
)


print("========================================")
print("       QDS + CLASSICAL SIGNATURE")
print("========================================")


# ========================================
# 1. SENDER KEY GENERATION
# ========================================

sender_private_key, sender_public_key = generate_key_pair()

register_public_key(
    "SENDER",
    sender_public_key
)

print("\n[1] SENDER KEY GENERATION")
print("Private key: Generated")
print("Public key: Generated")


# ========================================
# 2. SENDER SENDS MESSAGE
# ========================================

message = "Hello Receiver"

packet = create_secure_packet(
    message,
    sender_private_key,
    "SENDER"
)

print("\n[2] SENDER SENDS MESSAGE")
print("Message:")
print(message)


# ========================================
# 3. RECEIVER VERIFICATION
# ========================================

sender_trusted_public_key = get_public_key("SENDER")

result = verify_secure_packet(
    packet,
    sender_trusted_public_key
)

print("\n[3] RECEIVER VERIFICATION")

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


# ========================================
# 4. ATTACKER MODIFIES MESSAGE
# ========================================

tampered_packet = packet.copy()

tampered_packet["payload"] = packet["payload"].copy()

tampered_packet["payload"]["message"] = (
    "Hello Receiver!!!"
)

print("\n[4] ATTACKER MODIFIES MESSAGE")

tampered_result = verify_secure_packet(
    tampered_packet,
    sender_trusted_public_key
)

print(
    "Classical Signature:",
    tampered_result["classical_signature_valid"]
)

print(
    "FINAL DECISION:",
    tampered_result["final_decision"]
)


# ========================================
# 5. ATTACKER MODIFIES QDS DATA
# ========================================

quantum_attack_packet = packet.copy()

quantum_attack_packet["payload"] = (
    packet["payload"].copy()
)

quantum_attack_packet["payload"]["qds_signature"] = (
    packet["payload"]["qds_signature"].copy()
)

current_state = (
    quantum_attack_packet["payload"]
    ["qds_signature"]["quantum_state"]
)

states = ["Z", "X", "Y"]

for state in states:
    if state != current_state:
        quantum_attack_packet["payload"][
            "qds_signature"
        ]["quantum_state"] = state
        break


print("\n[5] ATTACKER MODIFIES QDS DATA")

quantum_attack_result = verify_secure_packet(
    quantum_attack_packet,
    sender_trusted_public_key
)

print(
    "Classical Signature:",
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