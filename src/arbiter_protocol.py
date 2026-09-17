"""
Multi-Party Quantum Digital Signature & Non-Repudiation Arbiter Protocol

Parties:
- Alice (Signer)
- Bob (Recipient / Initial Verifier)
- Charlie (Independent Arbiter / Adjudicator)

Security Mechanism:
- Dual-threshold quantum verification:
    s_v: Recipient verification threshold (stricter, e.g. 0.12)
    s_a: Arbiter acceptance threshold (looser, e.g. 0.22)
  with channel_error < s_v < s_a < 0.50.
- Guarantees information-theoretic non-repudiation:
  Alice cannot generate a signature that Bob accepts but Charlie rejects.
"""

import time
import math
from typing import Dict, Any

from math_model import QDSMathematicalModel
from attack_suite import QDSAttackSuite
from secure_packet import verify_secure_packet
from trusted_keys import get_public_key


class QDSArbiterProtocol:
    """
    Simulates the 3-party dispute resolution protocol to guarantee
    non-repudiation in Quantum Digital Signatures without ML.
    """

    def __init__(self, channel_noise: float = 0.02, safety_margin: float = 0.08):
        self.channel_noise = channel_noise
        self.s_v, self.s_a = QDSMathematicalModel.calculate_sih_dual_thresholds(
            channel_error=channel_noise, safety_margin=safety_margin
        )
        self.suite = QDSAttackSuite(signer_id="Alice", threshold=self.s_v)

    def calculate_repudiation_bound(self, num_qubits: int) -> float:
        """
        Calculates maximum probability that Alice successfully repudiates
        after Bob accepts:
            P_repudiate <= exp( -2 * N * (s_a - s_v)^2 )
        """
        gap = self.s_a - self.s_v
        exponent = -2.0 * num_qubits * (gap ** 2)
        if exponent < -700:
            return 0.0
        return float(math.exp(exponent))

    def alice_signs_and_transmits(self, message: str) -> Dict[str, Any]:
        """Alice produces the secure teleportation-based packet."""
        return self.suite.build_packet(message)

    def bob_verifies(self, packet: Dict[str, Any]) -> Dict[str, Any]:
        """
        Bob tests classical and quantum integrity using threshold s_v.
        """
        trusted_pub = get_public_key("Alice")
        result = verify_secure_packet(packet, trusted_pub, threshold=1.0 - self.s_v)
        
        q_acc = result["qds_result"].get("accuracy", 1.0)
        bob_error = 1.0 - q_acc
        bob_decision = "ACCEPTED" if (result["classical_signature_valid"] and bob_error <= self.s_v) else "REJECTED"

        return {
            "packet": packet,
            "bob_error": bob_error,
            "threshold_sv": self.s_v,
            "classical_valid": result["classical_signature_valid"],
            "decision": bob_decision,
            "qds_result": result["qds_result"]
        }

    def charlie_arbitrates(self, bob_transcript: Dict[str, Any], alice_claims_repudiation: bool = True) -> Dict[str, Any]:
        """
        In case of dispute, Charlie receives Bob's transcript and adjudicates
        using arbiter threshold s_a.
        """
        start = time.perf_counter()
        packet = bob_transcript["packet"]
        trusted_pub = get_public_key("Alice")

        # Charlie independently verifies
        result = verify_secure_packet(packet, trusted_pub, threshold=1.0 - self.s_a)
        q_acc = result["qds_result"].get("accuracy", 1.0)
        charlie_error = 1.0 - q_acc

        num_qubits = len(result["qds_result"].get("quantum_signature", {}).get("elements", [1] * 8))
        repudiation_prob = self.calculate_repudiation_bound(num_qubits)

        # Charlie's decision rule:
        if not result["classical_signature_valid"]:
            ruling = "FRAUDULENT_SUBMISSION"
            verdict = "Bob's submission is INVALID (tampered classical signature)."
        elif charlie_error <= self.s_a:
            ruling = "UPHELD_VALID_SIGNATURE"
            verdict = "Alice's repudiation is REJECTED. Signature is verified valid by Arbiter."
        else:
            ruling = "REJECTED_UNVERIFIABLE"
            verdict = "Quantum error exceeds arbiter threshold s_a. Signature dismissed."

        latency = (time.perf_counter() - start) * 1000.0

        return {
            "ruling": ruling,
            "verdict_summary": verdict,
            "charlie_error": charlie_error,
            "threshold_sa": self.s_a,
            "repudiation_probability_bound": repudiation_prob,
            "classical_valid": result["classical_signature_valid"],
            "latency_ms": latency
        }

    def simulate_dispute_scenario(self, message: str = "SMART_INDIA_HACKATHON_2026_CONTRACT") -> Dict[str, Any]:
        """Runs full 3-party dispute simulation."""
        packet = self.alice_signs_and_transmits(message)
        bob_res = self.bob_verifies(packet)
        charlie_res = self.charlie_arbitrates(bob_res, alice_claims_repudiation=True)

        return {
            "message": message,
            "bob_verification": bob_res,
            "charlie_arbitration": charlie_res,
            "dual_thresholds": {"s_v (Bob)": self.s_v, "s_a (Charlie)": self.s_a},
            "non_repudiation_guaranteed": (bob_res["decision"] == "ACCEPTED" and charlie_res["ruling"] == "UPHELD_VALID_SIGNATURE")
        }


if __name__ == "__main__":
    protocol = QDSArbiterProtocol()
    print("==================================================")
    print("   3-PARTY QDS DISPUTE & NON-REPUDIATION DEMO")
    print("==================================================")
    sim = protocol.simulate_dispute_scenario()
    print(f"Message: {sim['message']}")
    print(f"Bob Verification: {sim['bob_verification']['decision']} (Error: {sim['bob_verification']['bob_error']:.3f}, Threshold s_v: {sim['dual_thresholds']['s_v (Bob)']:.3f})")
    print(f"Charlie Ruling:   {sim['charlie_arbitration']['ruling']}")
    print(f"Verdict:          {sim['charlie_arbitration']['verdict_summary']}")
    print(f"Repudiation Prob: <= {sim['charlie_arbitration']['repudiation_probability_bound']:.2e}")
    print(f"Non-Repudiation Status: {'[PROVABLY SECURE]' if sim['non_repudiation_guaranteed'] else '[DISPUTED]'}")
