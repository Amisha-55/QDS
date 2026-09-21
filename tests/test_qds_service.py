import os
import sys
import unittest

# Ensure repo root and src/ are in sys.path
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SRC_DIR = os.path.join(REPO_ROOT, "src")
if REPO_ROOT not in sys.path:
    sys.path.insert(0, REPO_ROOT)
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from backend.qds import (
    QDSService,
    KeyManager,
    SecurityDecision,
    LikelyAttackType,
    secure_message,
    verify_message,
    reset_replay_cache,
)
from secure_packet import create_secure_packet
from classical_signature import generate_key_pair, sign_data


class TestQDSServiceIntegration(unittest.TestCase):

    def setUp(self):
        # Fresh key manager and service for each test
        import uuid
        self.run_id = uuid.uuid4().hex[:6]
        self.key_manager = KeyManager(allow_key_rotation=True)
        self.service = QDSService(
            key_manager=self.key_manager,
            default_shots=500,
            default_max_bits=8,
        )
        self.service.reset_replay_cache()

    def test_01_legitimate_message_flow(self):
        """1. Legitimate message: secure -> verify -> TRUSTED"""
        print("\n--- Test 1: Legitimate Message Flow ---")
        message = "SIH2026_Secure"
        sender_id = f"Alice_Test01_{self.run_id}"
        receiver_id = f"Bob_Test01_{self.run_id}"

        sec_res = self.service.secure_message(
            message=message,
            sender_id=sender_id,
            receiver_id=receiver_id,
        )

        self.assertTrue(sec_res.success, f"secure_message failed: {sec_res.error}")
        self.assertIsNotNone(sec_res.packet)
        self.assertIsNotNone(sec_res.signature_id)
        self.assertEqual(sec_res.sender_id, sender_id)
        self.assertEqual(sec_res.receiver_id, receiver_id)
        self.assertIn("bit_count", sec_res.quantum_stats)

        # Receiver verifies message
        ver_res = self.service.verify_message(sec_res.packet)

        self.assertTrue(ver_res.success)
        self.assertTrue(ver_res.classical_signature_valid)
        self.assertFalse(ver_res.replay_detected)
        self.assertTrue(ver_res.qds_valid)
        self.assertFalse(ver_res.attack_detected)
        self.assertEqual(ver_res.likely_attack_type, LikelyAttackType.LEGITIMATE)
        self.assertEqual(ver_res.final_decision, SecurityDecision.TRUSTED)
        print("  -> Passed: Legitimate packet verified as TRUSTED.")

    def test_02_message_tampering_forgery(self):
        """2. Message tampering: modified message -> verification failure"""
        print("\n--- Test 2: Message Tampering (Forgery) ---")
        sec_res = self.service.secure_message(
            message="Transfer 100",
            sender_id=f"Alice_Test02_{self.run_id}",
        )
        self.assertTrue(sec_res.success)

        # Simulate Forgery attack directly
        from forgery_attack import simulate_forgery
        forged_packet = simulate_forgery(
            sec_res.packet,
            forged_message="Transfer 1000000",
        )

        ver_res = self.service.verify_message(forged_packet)

        self.assertTrue(ver_res.success)
        self.assertFalse(ver_res.classical_signature_valid)
        self.assertTrue(ver_res.attack_detected)
        self.assertEqual(ver_res.likely_attack_type, LikelyAttackType.FORGERY)
        self.assertEqual(ver_res.final_decision, SecurityDecision.INVALID_SUSPICIOUS)
        print("  -> Passed: Message tampering detected and rejected.")

    def test_03_quantum_data_tampering(self):
        """3. Quantum/QDS data tampering: modified QDS elements -> verification failure"""
        print("\n--- Test 3: Quantum Data Tampering ---")
        sec_res = self.service.secure_message(
            message="QuantumDataSecret",
            sender_id=f"Alice_Test03_{self.run_id}",
        )
        self.assertTrue(sec_res.success)

        # Simulate Quantum data tampering directly
        from copy import deepcopy
        tampered_packet = deepcopy(sec_res.packet)
        elements = tampered_packet["payload"]["qds_signature"]["quantum_signature"]["elements"]
        if elements:
            elements[0]["bit"] = 1 - elements[0].get("bit", 0)
            elements[0]["expected_outcome"] = str(elements[0]["bit"])

        ver_res = self.service.verify_message(tampered_packet)

        # Because Ed25519 covers the entire payload (including qds_signature),
        # tampering with qds_signature inside payload breaks classical signature
        self.assertTrue(ver_res.success)
        self.assertFalse(ver_res.classical_signature_valid)
        self.assertTrue(ver_res.attack_detected)
        self.assertEqual(ver_res.final_decision, SecurityDecision.INVALID_SUSPICIOUS)
        print("  -> Passed: Quantum signature tampering detected and rejected.")

    def test_04_signer_impersonation(self):
        """4. Impersonation: attacker signs claiming legitimate signer -> verification failure"""
        print("\n--- Test 4: Signer Impersonation ---")
        sender_id = f"Alice_Test04_{self.run_id}"
        # Alice is legitimate signer
        _, alice_pub = self.key_manager.get_or_create_key_pair(sender_id)

        # Attacker signs packet with attacker private key, claiming to be Alice
        attacker_priv, _ = generate_key_pair()
        sec_res = self.service.secure_message(
            message="Impersonated Message",
            sender_id=sender_id,
            private_key=attacker_priv,
        )
        self.assertTrue(sec_res.success)

        # Receiver verifies against Alice's trusted key
        ver_res = self.service.verify_message(sec_res.packet)

        self.assertTrue(ver_res.success)
        self.assertFalse(ver_res.classical_signature_valid)
        self.assertTrue(ver_res.attack_detected)
        self.assertEqual(ver_res.final_decision, SecurityDecision.INVALID_SUSPICIOUS)
        print("  -> Passed: Impersonation attack detected and rejected.")

    def test_05_replay_attack_detection(self):
        """5. Replay: valid packet submitted twice -> second attempt detected"""
        print("\n--- Test 5: Replay Attack Detection ---")
        sec_res = self.service.secure_message(
            message="SingleUseToken",
            sender_id=f"Alice_Test05_{self.run_id}",
        )
        self.assertTrue(sec_res.success)

        # First submission: should succeed
        ver_res1 = self.service.verify_message(sec_res.packet)
        self.assertEqual(ver_res1.final_decision, SecurityDecision.TRUSTED)
        self.assertFalse(ver_res1.replay_detected)

        # Second submission (Replay attack): should be flagged
        ver_res2 = self.service.verify_message(sec_res.packet)
        self.assertTrue(ver_res2.success)
        self.assertTrue(ver_res2.replay_detected)
        self.assertTrue(ver_res2.attack_detected)
        self.assertEqual(ver_res2.likely_attack_type, LikelyAttackType.REPLAY)
        self.assertEqual(ver_res2.final_decision, SecurityDecision.INVALID_SUSPICIOUS)
        print("  -> Passed: Replay packet caught on second submission.")

    def test_06_malformed_packet_handling(self):
        """6. Invalid/malformed packet: returns structured failure without crashing"""
        print("\n--- Test 6: Malformed Packet Handling ---")

        # Not a dict
        res1 = self.service.verify_message("not-a-dict")  # type: ignore
        self.assertFalse(res1.success)
        self.assertEqual(res1.final_decision, SecurityDecision.INVALID_SUSPICIOUS)
        self.assertIsNotNone(res1.error)

        # Missing classical_signature
        res2 = self.service.verify_message({"payload": {}})
        self.assertFalse(res2.success)
        self.assertEqual(res2.final_decision, SecurityDecision.INVALID_SUSPICIOUS)

        # Missing required payload fields
        res3 = self.service.verify_message({
            "payload": {"signer_id": "Alice"},
            "classical_signature": "AAAA",
        })
        self.assertFalse(res3.success)
        self.assertEqual(res3.final_decision, SecurityDecision.INVALID_SUSPICIOUS)

        # Corrupted base64
        res4 = self.service.verify_message({
            "payload": {"signer_id": "Alice", "message": "Hi", "qds_signature": {}},
            "classical_signature": "!!!NotBase64!!!",
        })
        self.assertTrue(res4.success)
        self.assertFalse(res4.classical_signature_valid)
        self.assertEqual(res4.final_decision, SecurityDecision.INVALID_SUSPICIOUS)

        print("  -> Passed: All malformed packets handled safely with structured errors.")

    def test_07_backward_compatibility_with_legacy_packets(self):
        """7. Backward compatibility: verify packets created directly by secure_packet.create_secure_packet"""
        print("\n--- Test 7: Legacy Packet Backward Compatibility ---")
        legacy_id = f"Alice_Legacy_{self.run_id}"
        priv, pub = self.key_manager.get_or_create_key_pair(legacy_id)

        # Create legacy packet (lacks top-level signature_id, only inside qds_signature)
        legacy_packet = create_secure_packet(
            message="LegacyMsg",
            private_key=priv,
            signer_id=legacy_id,
        )

        # Verify using QDSService
        ver_res = self.service.verify_message(legacy_packet)

        self.assertTrue(ver_res.success)
        self.assertTrue(ver_res.classical_signature_valid)
        self.assertFalse(ver_res.replay_detected)
        self.assertTrue(ver_res.qds_valid)
        self.assertEqual(ver_res.final_decision, SecurityDecision.TRUSTED)
        print("  -> Passed: Legacy packet verified successfully.")


if __name__ == "__main__":
    print("=" * 60)
    print("   RUNNING QDS INTEGRATION SERVICE TEST SUITE")
    print("=" * 60)
    unittest.main(verbosity=2)
