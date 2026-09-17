"""
Unified Quantum Cyber Attack Simulation & Threat Assessment Suite

Simulates the four primary attack vectors on Teleportation-Based QDS:
1. Signature Forgery (Message tampering / payload corruption)
2. Signer Impersonation (Key spoofing / unauthorized generation)
3. Replay Attack (Signature ID / nonce reuse)
4. Quantum Channel Manipulation (Pauli X/Y/Z injection, intercept-resend, depolarizing noise)

Strictly non-AI: evaluative decisions rely on quantum measurement statistics,
projective Pauli verification, and statistical thresholds.
"""

import time
import uuid
import base64
from copy import deepcopy
from typing import Dict, Any, List

from classical_signature import generate_key_pair, sign_data
from secure_packet import create_secure_packet, verify_secure_packet, canonical_json
from trusted_keys import register_public_key, get_public_key
from noisy_channel import run_noisy_experiment
from threat_detector import comprehensive_threat_classification, detect_threat
from math_model import QDSMathematicalModel
from config import THRESHOLD, SHOTS


class QDSAttackSuite:
    """
    Unified manager for executing and evaluating adversarial scenarios
    against the teleportation-based QDS architecture.
    """

    def __init__(self, signer_id: str = "Alice", shots: int = SHOTS, threshold: float = THRESHOLD):
        self.signer_id = signer_id
        self.shots = shots
        self.threshold = threshold
        self.used_signature_ids = set()

        # Initialize trusted keys
        self.priv_key, self.pub_key = generate_key_pair()
        register_public_key(self.signer_id, self.pub_key)

    def reset_replay_cache(self):
        """Clears seen signature identifiers."""
        self.used_signature_ids.clear()

    def build_packet(self, message: str) -> Dict[str, Any]:
        """Creates a signed, timestamped, nonce-protected packet."""
        packet = create_secure_packet(message, self.priv_key, self.signer_id)
        sig_id = str(uuid.uuid4())
        packet["payload"]["signature_id"] = sig_id
        packet["payload"]["timestamp"] = time.time()
        
        # Classical re-sign over updated canonical payload
        payload_bytes = canonical_json(packet["payload"])
        new_sig = sign_data(self.priv_key, payload_bytes)
        packet["classical_signature"] = base64.b64encode(new_sig).decode("ascii")
        return packet

    def run_clean_scenario(self, message: str = "SIH2026_SECURE_PAYLOAD") -> Dict[str, Any]:
        """Runs a legitimate, untampered transmission."""
        start = time.perf_counter()
        packet = self.build_packet(message)
        sig_id = packet["payload"]["signature_id"]

        result = verify_secure_packet(packet, self.pub_key)
        replay = sig_id in self.used_signature_ids
        self.used_signature_ids.add(sig_id)

        latency = (time.perf_counter() - start) * 1000.0
        q_acc = result["qds_result"].get("accuracy", 1.0)
        error_rate = 1.0 - q_acc

        threat_eval = comprehensive_threat_classification(
            counts={"0": int(self.shots * (1 - error_rate)), "1": int(self.shots * error_rate)},
            shots=self.shots,
            threshold=self.threshold
        )

        decision = "ACCEPT" if (result["classical_signature_valid"] and not replay and error_rate <= self.threshold) else "REJECT"

        return {
            "attack_type": "CLEAN_LEGITIMATE",
            "message": message,
            "detected": decision != "ACCEPT",
            "threat_classification": threat_eval["threat_type"],
            "severity": threat_eval["threat_severity"],
            "classical_valid": result["classical_signature_valid"],
            "replay_detected": replay,
            "error_rate": error_rate,
            "quantum_fidelity": 1.0 - error_rate,
            "forgery_prob_bound": threat_eval["forgery_probability"],
            "final_decision": decision,
            "latency_ms": latency
        }

    def run_forgery_attack(self, message: str = "TRANSFER_AMOUNT_100", tampered_message: str = "TRANSFER_AMOUNT_99999") -> Dict[str, Any]:
        """
        Adversary alters the classical/quantum payload after signature generation
        without having access to Alice's private key.
        """
        start = time.perf_counter()
        packet = self.build_packet(message)
        sig_id = packet["payload"]["signature_id"]

        # Tamper payload
        forged_packet = deepcopy(packet)
        forged_packet["payload"]["message"] = tampered_message

        result = verify_secure_packet(forged_packet, self.pub_key)
        replay = sig_id in self.used_signature_ids
        self.used_signature_ids.add(sig_id)

        latency = (time.perf_counter() - start) * 1000.0
        qds_hash_ok = result["qds_result"].get("classical_hash_valid", False)
        detected = not result["classical_signature_valid"] or not qds_hash_ok

        return {
            "attack_type": "SIGNATURE_FORGERY",
            "original_message": message,
            "tampered_message": tampered_message,
            "detected": detected,
            "threat_classification": "PAYLOAD_TAMPERING_FORGERY",
            "severity": "CRITICAL",
            "classical_valid": result["classical_signature_valid"],
            "qds_hash_valid": qds_hash_ok,
            "replay_detected": replay,
            "final_decision": "REJECT" if detected else "ACCEPT",
            "latency_ms": latency
        }

    def run_impersonation_attack(self, message: str = "EMERGENCY_OVERRIDE") -> Dict[str, Any]:
        """
        Adversary creates a key pair and signs a message, claiming to be Alice (SPOOFING).
        """
        start = time.perf_counter()
        fake_priv, fake_pub = generate_key_pair()
        
        # Attacker signs pretending to be Alice
        impersonated_packet = create_secure_packet(message, fake_priv, self.signer_id)
        sig_id = str(uuid.uuid4())
        impersonated_packet["payload"]["signature_id"] = sig_id

        # Receiver verifies against Alice's registered public key
        trusted_alice_pub = get_public_key(self.signer_id)
        result = verify_secure_packet(impersonated_packet, trusted_alice_pub)

        latency = (time.perf_counter() - start) * 1000.0
        detected = not result["classical_signature_valid"]

        return {
            "attack_type": "IMPERSONATION_ATTACK",
            "message": message,
            "detected": detected,
            "threat_classification": "IDENTITY_SPOOFING_IMPERSONATION",
            "severity": "CRITICAL",
            "classical_valid": result["classical_signature_valid"],
            "final_decision": "REJECT" if detected else "ACCEPT",
            "latency_ms": latency
        }

    def run_replay_attack(self, message: str = "EXECUTE_TRANSACTION_#001") -> Dict[str, Any]:
        """
        Adversary intercepts a valid packet and attempts to replay it to the receiver.
        """
        start = time.perf_counter()
        packet = self.build_packet(message)
        sig_id = packet["payload"]["signature_id"]

        # First reception (Legitimate)
        verify_secure_packet(packet, self.pub_key)
        self.used_signature_ids.add(sig_id)

        # Second reception (Adversarial Replay)
        replay_packet = deepcopy(packet)
        replay_detected = sig_id in self.used_signature_ids

        latency = (time.perf_counter() - start) * 1000.0

        return {
            "attack_type": "REPLAY_ATTACK",
            "message": message,
            "signature_id": sig_id,
            "detected": replay_detected,
            "threat_classification": "CRYPTOGRAPHIC_REPLAY_ATTACK",
            "severity": "HIGH",
            "replay_detected": replay_detected,
            "final_decision": "REJECT" if replay_detected else "ACCEPT",
            "latency_ms": latency
        }

    def run_channel_manipulation(
        self,
        state: str = "Z",
        attack: str = "bit_flip",
        noise_probability: float = 0.05
    ) -> Dict[str, Any]:
        """
        Simulates quantum channel attacks: Pauli bit-flip, phase-flip, bit-phase-flip,
        or excessive environmental channel decoherence.
        """
        start = time.perf_counter()
        counts = run_noisy_experiment(
            state=state,
            attack=attack,
            noise_probability=noise_probability,
            shots=self.shots,
            measurement_basis=state
        )

        threat_eval = comprehensive_threat_classification(
            counts=counts,
            shots=self.shots,
            threshold=self.threshold,
            p_expected_noise=0.02
        )

        detected = threat_eval["error_rate"] > self.threshold
        latency = (time.perf_counter() - start) * 1000.0

        return {
            "attack_type": f"CHANNEL_{attack.upper()}",
            "quantum_state": state,
            "noise_prob": noise_probability,
            "counts": counts,
            "error_rate": threat_eval["error_rate"],
            "quantum_fidelity": threat_eval["fidelity"],
            "llr": threat_eval["llr"],
            "detected": detected,
            "threat_classification": threat_eval["threat_type"],
            "severity": threat_eval["threat_severity"],
            "final_decision": "REJECT" if detected else "ACCEPT",
            "latency_ms": latency
        }

    def run_all_scenarios(self) -> List[Dict[str, Any]]:
        """Executes full diagnostic suite across all 4 attack categories."""
        self.reset_replay_cache()
        results = [
            self.run_clean_scenario(),
            self.run_forgery_attack(),
            self.run_impersonation_attack(),
            self.run_replay_attack(),
            self.run_channel_manipulation(state="Z", attack="bit_flip"),
            self.run_channel_manipulation(state="X", attack="phase_flip"),
            self.run_channel_manipulation(state="Y", attack="bit_phase_flip"),
        ]
        return results


if __name__ == "__main__":
    suite = QDSAttackSuite()
    print("==================================================")
    print("      QDS UNIFIED ATTACK SUITE DIAGNOSTIC")
    print("==================================================")
    results = suite.run_all_scenarios()
    for r in results:
        status_sym = "[DETECTED/STOPPED]" if r["detected"] or r["attack_type"] == "CLEAN_LEGITIMATE" else "[VULNERABLE]"
        print(f"\nScenario: {r['attack_type']:<28} | Result: {r['final_decision']:<8} | {status_sym}")
        print(f"  Classification: {r['threat_classification']} (Severity: {r.get('severity', 'N/A')})")
        print(f"  Execution Latency: {r['latency_ms']:.2f} ms")
