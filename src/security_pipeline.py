"""
End-to-End QDS Security Pipeline

Stages:
    A. Signature Generation  (qds_signature)
    B. Secure Packet + Auth  (secure_packet, classical_signature, trusted_keys)
    C. Receiver Verification (qds_verify, secure_packet)
    D. Attack/Threat Testing (forgery, impersonation, replay, channel, detectors)
    E. Final Security Evaluation (TP / TN / FP / FN + dataset)
"""

import csv
import os
import uuid
import base64
import secrets
from copy import deepcopy
from datetime import datetime, timezone

from classical_signature import generate_key_pair, sign_data
from secure_packet import (
    create_secure_packet,
    verify_secure_packet,
    canonical_json,
)
from trusted_keys import register_public_key
from qds_verify import verify_signature
from noisy_channel import run_noisy_experiment
from multi_state_detector import run_multi_state_test
from threat_detector import detect_threat, calculate_error_rate
from config import SHOTS, NOISE_PROBABILITY, NOISE_THRESHOLDS


# ============================================================
# CONSTANTS
# ============================================================

PIPELINE_VERSION = "1.0"

DEFAULT_THRESHOLD = 0.95          # QDS verification accuracy threshold
DEFAULT_NOISE_PROBABILITY = 0.02
DEFAULT_SHOTS = 1000
MAX_BITS = 8                      # keep circuits small for experiments

SIGNER_ID = "Alice"

MESSAGES = [
    "SIH26141",
    "QuantumSecure",
    "HelloBob",
    "TestMsg42",
    "SecretData",
]

EXPERIMENTS_PER_ATTACK = 10       # per attack type

OUTPUT_FILE = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "data",
    "pipeline_security_dataset.csv",
)

DATASET_COLUMNS = [
    "experiment_id",
    "experiment_number",
    "pipeline_version",
    "attack_type",
    "message",
    "quantum_state",
    "shots",
    "zero_count",
    "one_count",
    "probability_0",
    "probability_1",
    "error_rate",
    "quantum_accuracy",
    "noise_probability",
    "threshold",
    "classical_signature_valid",
    "qds_valid",
    "replay_detected",
    "attack_detected",
    "final_decision",
    "ground_truth",
]


# ============================================================
# REPLAY REGISTRY  (in-memory for the pipeline run)
# ============================================================

_USED_SIGNATURE_IDS = set()


def check_replay(signature_id):
    """Return True if this signature_id was already seen."""
    if signature_id in _USED_SIGNATURE_IDS:
        return True
    _USED_SIGNATURE_IDS.add(signature_id)
    return False


def reset_replay_registry():
    """Clear between experiment batches if needed."""
    _USED_SIGNATURE_IDS.clear()


# ============================================================
# A. SIGNATURE GENERATION  (delegated to qds_signature)
#    called internally by create_secure_packet
# ============================================================


# ============================================================
# B. SECURE PACKET + AUTHENTICATION
# ============================================================

def build_legitimate_packet(message, private_key, signer_id):
    """
    Create a legitimate secure packet and stamp it with a
    unique signature_id for replay detection.
    """
    packet = create_secure_packet(
        message,
        private_key,
        signer_id,
    )

    # Add replay-protection metadata and re-sign
    sig_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    packet["payload"]["signature_id"] = sig_id
    packet["payload"]["timestamp"] = timestamp

    # Re-sign to cover the new fields
    payload_bytes = canonical_json(packet["payload"])
    new_sig = sign_data(private_key, payload_bytes)
    packet["classical_signature"] = base64.b64encode(
        new_sig
    ).decode("ascii")

    return packet


# ============================================================
# C. RECEIVER VERIFICATION
# ============================================================

def verify_packet(packet, public_key, threshold=DEFAULT_THRESHOLD):
    """
    Full receiver-side verification:
      1. Ed25519 classical signature check
      2. QDS-inspired quantum verification
      3. Replay check
    Returns a result dict.
    """
    result = verify_secure_packet(packet, public_key)

    # Replay check
    sig_id = packet.get("payload", {}).get("signature_id", "")
    replay = False
    if sig_id:
        replay = check_replay(sig_id)

    result["replay_detected"] = replay

    # Override final decision if replay found
    if replay:
        result["final_decision"] = "INVALID / SUSPICIOUS"

    return result


# ============================================================
# D. ATTACK SCENARIOS
# ============================================================

def simulate_forgery(packet):
    """
    Attacker modifies the message inside an existing packet
    without re-signing.
    """
    forged = deepcopy(packet)
    original_msg = forged["payload"]["message"]
    forged["payload"]["message"] = "FORGED-" + original_msg
    return forged


def simulate_impersonation(message, signer_id):
    """
    Attacker generates their own key pair but claims to be
    the legitimate signer.
    """
    attacker_priv, _attacker_pub = generate_key_pair()
    packet = build_legitimate_packet(
        message,
        attacker_priv,
        signer_id,
    )
    return packet


def simulate_replay(packet):
    """
    Attacker re-sends an exact copy of a previously accepted
    packet (same signature_id).
    """
    return deepcopy(packet)


def simulate_channel_attack(state, noise_probability, shots):
    """
    Run a noisy-channel quantum experiment with an explicit
    Pauli attack (bit_flip) to simulate a channel-level attack.
    Returns measurement counts.
    """
    counts = run_noisy_experiment(
        state=state,
        attack="bit_flip",
        noise_probability=noise_probability,
        shots=shots,
        measurement_basis=state,
    )
    return counts


# ============================================================
# HELPER — extract quantum stats from a verified packet
# ============================================================

def extract_quantum_stats(packet, verification_result):
    """
    Pull representative quantum measurement statistics out of
    the QDS signature embedded in the packet.
    """
    qds_sig = packet["payload"].get("qds_signature", {})
    q_sig = qds_sig.get("quantum_signature", {})
    elements = q_sig.get("elements", [])
    overall_accuracy = q_sig.get("overall_accuracy", 0.0)

    # Grab the first element's stats as representative row data
    if elements:
        first = elements[0]
        basis = first.get("basis", "Z")
        counts = first.get("measurement_results", {})
        shots = first.get("shots", DEFAULT_SHOTS)

        zero_count = 0
        one_count = 0
        for outcome, count in counts.items():
            if not outcome:
                continue
            bob_bit = int(outcome[0])
            if bob_bit == 0:
                zero_count += count
            else:
                one_count += count

        total = zero_count + one_count
        p0 = zero_count / total if total > 0 else 0.0
        p1 = one_count / total if total > 0 else 0.0
        error_rate = 1.0 - overall_accuracy
    else:
        basis = "Z"
        shots = DEFAULT_SHOTS
        zero_count = 0
        one_count = 0
        p0 = 0.0
        p1 = 0.0
        error_rate = 1.0

    return {
        "quantum_state": basis,
        "shots": shots,
        "zero_count": zero_count,
        "one_count": one_count,
        "probability_0": round(p0, 4),
        "probability_1": round(p1, 4),
        "error_rate": round(error_rate, 4),
        "quantum_accuracy": round(overall_accuracy, 4),
    }


# ============================================================
# E. SINGLE EXPERIMENT RUNNER
# ============================================================

def run_single_experiment(
    attack_type,
    message,
    alice_private_key,
    alice_public_key,
    noise_probability=DEFAULT_NOISE_PROBABILITY,
    threshold=DEFAULT_THRESHOLD,
    experiment_number=1,
):
    """
    Run one complete pipeline experiment for the given attack type.

    attack_type: LEGITIMATE | FORGERY | IMPERSONATION | REPLAY | CHANNEL_ATTACK
    Returns a dict matching DATASET_COLUMNS.
    """

    row = {
        "experiment_id": str(uuid.uuid4()),
        "experiment_number": experiment_number,
        "pipeline_version": PIPELINE_VERSION,
        "attack_type": attack_type,
        "message": message,
        "noise_probability": noise_probability,
        "threshold": threshold,
        "replay_detected": False,
        "ground_truth": attack_type != "LEGITIMATE",
    }

    # --------------------------------------------------
    # LEGITIMATE
    # --------------------------------------------------
    if attack_type == "LEGITIMATE":
        packet = build_legitimate_packet(
            message, alice_private_key, SIGNER_ID
        )
        result = verify_packet(packet, alice_public_key, threshold)

        stats = extract_quantum_stats(packet, result)
        row.update(stats)

        row["classical_signature_valid"] = result["classical_signature_valid"]
        row["qds_valid"] = result.get("qds_result", {}).get("decision", "NOT VERIFIED") == "VALID"
        row["replay_detected"] = result["replay_detected"]
        row["attack_detected"] = result["final_decision"] != "TRUSTED"
        row["final_decision"] = result["final_decision"]

    # --------------------------------------------------
    # FORGERY
    # --------------------------------------------------
    elif attack_type == "FORGERY":
        packet = build_legitimate_packet(
            message, alice_private_key, SIGNER_ID
        )
        forged = simulate_forgery(packet)
        result = verify_packet(forged, alice_public_key, threshold)

        stats = extract_quantum_stats(forged, result)
        row.update(stats)

        row["classical_signature_valid"] = result["classical_signature_valid"]
        row["qds_valid"] = result.get("qds_result", {}).get("decision", "NOT VERIFIED") == "VALID"
        row["replay_detected"] = result["replay_detected"]
        row["attack_detected"] = result["final_decision"] != "TRUSTED"
        row["final_decision"] = result["final_decision"]

    # --------------------------------------------------
    # IMPERSONATION
    # --------------------------------------------------
    elif attack_type == "IMPERSONATION":
        impersonated = simulate_impersonation(message, SIGNER_ID)
        result = verify_packet(impersonated, alice_public_key, threshold)

        stats = extract_quantum_stats(impersonated, result)
        row.update(stats)

        row["classical_signature_valid"] = result["classical_signature_valid"]
        row["qds_valid"] = result.get("qds_result", {}).get("decision", "NOT VERIFIED") == "VALID"
        row["replay_detected"] = result["replay_detected"]
        row["attack_detected"] = result["final_decision"] != "TRUSTED"
        row["final_decision"] = result["final_decision"]

    # --------------------------------------------------
    # REPLAY
    # --------------------------------------------------
    elif attack_type == "REPLAY":
        packet = build_legitimate_packet(
            message, alice_private_key, SIGNER_ID
        )
        # First accept the original
        _first_result = verify_packet(packet, alice_public_key, threshold)

        # Now replay
        replayed = simulate_replay(packet)
        result = verify_packet(replayed, alice_public_key, threshold)

        stats = extract_quantum_stats(replayed, result)
        row.update(stats)

        row["classical_signature_valid"] = result["classical_signature_valid"]
        row["qds_valid"] = result.get("qds_result", {}).get("decision", "NOT VERIFIED") == "VALID"
        row["replay_detected"] = result["replay_detected"]
        row["attack_detected"] = result["replay_detected"]  # replay is the attack signal
        row["final_decision"] = result["final_decision"]

    # --------------------------------------------------
    # CHANNEL_ATTACK  (quantum-level noise / Pauli attack)
    # --------------------------------------------------
    elif attack_type == "CHANNEL_ATTACK":
        state = secrets.choice(["Z", "X", "Y"])
        counts = simulate_channel_attack(
            state, noise_probability, DEFAULT_SHOTS
        )

        zero_count = counts.get("0", 0)
        one_count = counts.get("1", 0)
        total = zero_count + one_count
        p0 = zero_count / total if total > 0 else 0.0
        p1 = one_count / total if total > 0 else 0.0

        # Use the noise-aware threshold from config if available
        noise_threshold = NOISE_THRESHOLDS.get(
            noise_probability, 0.0186
        )
        error_rate = p1  # deviation from ideal |0> outcome
        detected = error_rate > noise_threshold

        row["quantum_state"] = state
        row["shots"] = DEFAULT_SHOTS
        row["zero_count"] = zero_count
        row["one_count"] = one_count
        row["probability_0"] = round(p0, 4)
        row["probability_1"] = round(p1, 4)
        row["error_rate"] = round(error_rate, 4)
        row["quantum_accuracy"] = round(1.0 - error_rate, 4)
        row["classical_signature_valid"] = "N/A"
        row["qds_valid"] = "N/A"
        row["replay_detected"] = False
        row["attack_detected"] = detected
        row["final_decision"] = "INVALID / SUSPICIOUS" if detected else "TRUSTED"

    else:
        raise ValueError(f"Unknown attack_type: {attack_type}")

    return row


# ============================================================
# E. FULL PIPELINE — run all experiments + evaluation
# ============================================================

ATTACK_TYPES = [
    "LEGITIMATE",
    "FORGERY",
    "IMPERSONATION",
    "REPLAY",
    "CHANNEL_ATTACK",
]


def run_pipeline(
    experiments_per_attack=EXPERIMENTS_PER_ATTACK,
    noise_probability=DEFAULT_NOISE_PROBABILITY,
    threshold=DEFAULT_THRESHOLD,
    save_dataset=True,
):
    """
    Run the complete security pipeline across all attack types,
    collect results, compute TP/TN/FP/FN, and optionally save
    the dataset CSV.
    """

    print()
    print("=" * 60)
    print("     QDS END-TO-END SECURITY PIPELINE")
    print("=" * 60)
    print(f"\nPipeline Version : {PIPELINE_VERSION}")
    print(f"Experiments/attack: {experiments_per_attack}")
    print(f"Noise probability : {noise_probability}")
    print(f"QDS threshold     : {threshold}")
    print(f"Messages pool     : {len(MESSAGES)}")

    # Generate keys and register
    alice_private, alice_public = generate_key_pair()
    register_public_key(SIGNER_ID, alice_public)
    print(f"\n{SIGNER_ID}'s Ed25519 key pair generated and registered.")

    rows = []
    experiment_number = 1

    for attack_type in ATTACK_TYPES:

        print(f"\n--- Running {attack_type} experiments ---")

        for i in range(experiments_per_attack):

            message = MESSAGES[i % len(MESSAGES)]

            row = run_single_experiment(
                attack_type=attack_type,
                message=message,
                alice_private_key=alice_private,
                alice_public_key=alice_public,
                noise_probability=noise_probability,
                threshold=threshold,
                experiment_number=experiment_number,
            )

            rows.append(row)
            experiment_number += 1

            print(
                f"  [{experiment_number - 1}] {attack_type:20s} | "
                f"detected={str(row['attack_detected']):5s} | "
                f"decision={row['final_decision']}"
            )

    # --------------------------------------------------------
    # EVALUATION — TP / TN / FP / FN
    # --------------------------------------------------------

    tp = 0  # attack happened AND detected
    tn = 0  # no attack AND accepted
    fp = 0  # no attack BUT flagged
    fn = 0  # attack happened BUT accepted

    for row in rows:
        is_attack = row["ground_truth"]
        detected = row["attack_detected"]

        if is_attack and detected:
            tp += 1
        elif not is_attack and not detected:
            tn += 1
        elif not is_attack and detected:
            fp += 1
        elif is_attack and not detected:
            fn += 1

    total = tp + tn + fp + fn
    accuracy = (tp + tn) / total if total > 0 else 0.0
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = (
        2 * precision * recall / (precision + recall)
        if (precision + recall) > 0
        else 0.0
    )

    print()
    print("=" * 60)
    print("     SECURITY EVALUATION RESULTS")
    print("=" * 60)
    print(f"\nTotal experiments : {total}")
    print(f"True  Positives   : {tp}")
    print(f"True  Negatives   : {tn}")
    print(f"False Positives   : {fp}")
    print(f"False Negatives   : {fn}")
    print(f"\nAccuracy          : {accuracy:.4f}")
    print(f"Precision         : {precision:.4f}")
    print(f"Recall            : {recall:.4f}")
    print(f"F1 Score          : {f1:.4f}")

    # Per-attack breakdown
    print()
    print("-" * 60)
    print("Per-Attack Breakdown")
    print("-" * 60)

    for attack_type in ATTACK_TYPES:
        attack_rows = [r for r in rows if r["attack_type"] == attack_type]
        detected_count = sum(1 for r in attack_rows if r["attack_detected"])
        total_count = len(attack_rows)

        if attack_type == "LEGITIMATE":
            # For legitimate, "detected" means false positive
            print(
                f"  {attack_type:20s}: "
                f"{total_count - detected_count}/{total_count} correctly accepted  "
                f"(FP={detected_count})"
            )
        else:
            print(
                f"  {attack_type:20s}: "
                f"{detected_count}/{total_count} attacks detected  "
                f"(FN={total_count - detected_count})"
            )

    # --------------------------------------------------------
    # SAVE DATASET
    # --------------------------------------------------------

    if save_dataset:

        os.makedirs(
            os.path.dirname(OUTPUT_FILE),
            exist_ok=True,
        )

        with open(
            OUTPUT_FILE,
            "w",
            newline="",
            encoding="utf-8",
        ) as f:
            writer = csv.DictWriter(f, fieldnames=DATASET_COLUMNS)
            writer.writeheader()
            writer.writerows(rows)

        print(f"\nDataset saved to:\n{OUTPUT_FILE}")
        print(f"Total rows: {len(rows)}")

    print("\n" + "=" * 60)

    return rows, {
        "tp": tp,
        "tn": tn,
        "fp": fp,
        "fn": fn,
        "accuracy": accuracy,
        "precision": precision,
        "recall": recall,
        "f1": f1,
    }




if __name__ == "__main__":
    run_pipeline()
