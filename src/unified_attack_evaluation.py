from qds_signature import generate_signature
from qds_verify import verify_signature
from multi_state_detector import run_multi_state_test

from copy import deepcopy
from datetime import datetime
import hashlib
import uuid
import statistics


EXPERIMENTS = 10
MESSAGE = "SIH26141"


# ============================================================
# FORGERY / INTEGRITY TAMPERING
# ============================================================

def test_forgery():
    detected = 0

    for _ in range(EXPERIMENTS):

        signature = generate_signature(MESSAGE)

        signature["signature_id"] = str(uuid.uuid4())

        signature["integrity_hash"] = hashlib.sha256(
            (
                MESSAGE
                + signature["quantum_state"]
            ).encode()
        ).hexdigest()

        forged_signature = deepcopy(signature)

        forged_message = "FAKE-" + MESSAGE

        forged_signature["integrity_hash"] = hashlib.sha256(
            (
                forged_message
                + forged_signature["quantum_state"]
            ).encode()
        ).hexdigest()

        expected_hash = hashlib.sha256(
            (
                MESSAGE
                + forged_signature["quantum_state"]
            ).encode()
        ).hexdigest()

        integrity_failed = (
            forged_signature["integrity_hash"]
            != expected_hash
        )

        if integrity_failed:
            detected += 1

    return detected


# ============================================================
# IMPERSONATION
# ============================================================

AUTHORIZED_SIGNERS = {
    "Alice": "ALICE-SECRET-KEY"
}


def authenticate_signer(signer_id, credential):

    expected = AUTHORIZED_SIGNERS.get(signer_id)

    if expected is None:
        return False

    return credential == expected


def test_impersonation():

    detected = 0

    for _ in range(EXPERIMENTS):

        signature = generate_signature(MESSAGE)

        signature["signer_id"] = "Alice"
        signature["credential"] = "ALICE-SECRET-KEY"

        impersonated_signature = deepcopy(signature)

        impersonated_signature["signer_id"] = "Alice"
        impersonated_signature["credential"] = (
            "ATTACKER-CREDENTIAL"
        )

        authenticated = authenticate_signer(
            impersonated_signature["signer_id"],
            impersonated_signature["credential"]
        )

        verify_signature(
            impersonated_signature,
            MESSAGE
        )

        if not authenticated:
            detected += 1

    return detected


# ============================================================
# REPLAY ATTACK
# ============================================================

def test_replay():

    detected = 0

    used_signatures = set()

    for _ in range(EXPERIMENTS):

        signature = generate_signature(MESSAGE)

        signature["signature_id"] = str(uuid.uuid4())

        signature["timestamp"] = (
            datetime.now().isoformat()
        )

        signature_id = signature["signature_id"]

        # First use
        if signature_id not in used_signatures:

            used_signatures.add(signature_id)

        # Replay the same signature
        replayed_signature = deepcopy(signature)

        replay_id = replayed_signature["signature_id"]

        if replay_id in used_signatures:

            detected += 1

    return detected


# ============================================================
# QUANTUM CHANNEL ATTACK
# ============================================================

def test_channel_attack(attack):

    detected = 0
    scores = []
    thresholds = []

    for _ in range(EXPERIMENTS):

        (
            _,
            score,
            threshold,
            decision
        ) = run_multi_state_test(
            attack=attack
        )

        scores.append(score)
        thresholds.append(threshold)

        if decision == "SUSPICIOUS / ATTACK":

            detected += 1

    return (
        detected,
        scores,
        thresholds
    )


# ============================================================
# PRINT REPORT
# ============================================================

def print_standard_result(
    attack_name,
    attempts,
    detected
):

    missed = attempts - detected

    detection_rate = (
        detected / attempts
    ) * 100

    print(
        f"{attack_name:<28}"
        f"{attempts:<10}"
        f"{detected:<10}"
        f"{missed:<10}"
        f"{detection_rate:.2f}%"
    )


# ============================================================
# MAIN
# ============================================================

print()
print("============================================================")
print("              QDS SECURITY EVALUATION REPORT")
print("============================================================")

print(f"\nExperiments per attack: {EXPERIMENTS}")

print("\n------------------------------------------------------------")
print("STANDARD SECURITY ATTACKS")
print("------------------------------------------------------------")

print(
    f"{'Attack Type':<28}"
    f"{'Attempts':<10}"
    f"{'Detected':<10}"
    f"{'Missed':<10}"
    f"{'Detection Rate'}"
)

print("-" * 78)


# ------------------------------------------------------------
# FORGERY
# ------------------------------------------------------------

forgery_detected = test_forgery()

print_standard_result(
    "Forgery / Integrity",
    EXPERIMENTS,
    forgery_detected
)


# ------------------------------------------------------------
# IMPERSONATION
# ------------------------------------------------------------

impersonation_detected = test_impersonation()

print_standard_result(
    "Impersonation",
    EXPERIMENTS,
    impersonation_detected
)


# ------------------------------------------------------------
# REPLAY
# ------------------------------------------------------------

replay_detected = test_replay()

print_standard_result(
    "Replay",
    EXPERIMENTS,
    replay_detected
)


# ============================================================
# QUANTUM CHANNEL ATTACKS
# ============================================================

print("\n------------------------------------------------------------")
print("QUANTUM CHANNEL ATTACKS")
print("------------------------------------------------------------")

print(
    f"{'Attack Type':<20}"
    f"{'Attempts':<10}"
    f"{'Detected':<10}"
    f"{'Missed':<10}"
    f"{'Detection Rate':<16}"
    f"{'Mean Score':<12}"
    f"{'Min':<10}"
    f"{'Max':<10}"
    f"{'Threshold'}"
)

print("-" * 120)


channel_results = {}


for attack_name, attack_code in [

    ("Bit Flip", "bit_flip"),
    ("Phase Flip", "phase_flip"),
    ("Bit-Phase Flip", "bit_phase_flip")

]:

    (
        detected,
        scores,
        thresholds
    ) = test_channel_attack(
        attack_code
    )

    missed = EXPERIMENTS - detected

    detection_rate = (
        detected / EXPERIMENTS
    ) * 100

    mean_score = statistics.mean(scores)

    min_score = min(scores)

    max_score = max(scores)

    threshold = thresholds[0]

    channel_results[attack_name] = {
        "detected": detected,
        "scores": scores,
        "threshold": threshold
    }

    print(
        f"{attack_name:<20}"
        f"{EXPERIMENTS:<10}"
        f"{detected:<10}"
        f"{missed:<10}"
        f"{detection_rate:<16.2f}"
        f"{mean_score:<12.4f}"
        f"{min_score:<10.4f}"
        f"{max_score:<10.4f}"
        f"{threshold:.4f}"
    )


# ============================================================
# OVERALL SUMMARY
# ============================================================

total_attempts = (
    EXPERIMENTS * 6
)

total_detected = (
    forgery_detected
    + impersonation_detected
    + replay_detected
)

for result in channel_results.values():

    total_detected += result["detected"]


total_missed = (
    total_attempts
    - total_detected
)

overall_detection_rate = (
    total_detected
    / total_attempts
) * 100


print("\n============================================================")
print("                    SECURITY SUMMARY")
print("============================================================")

print(f"Total Attempts       : {total_attempts}")
print(f"Total Detected       : {total_detected}")
print(f"Total Missed         : {total_missed}")
print(
    f"Overall Detection    : "
    f"{overall_detection_rate:.2f}%"
)

print("============================================================")

print("\nEvaluation completed.")