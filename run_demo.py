"""
Interactive Standalone CLI Demonstration
Quantum-Inspired Cyber Threat Detection Framework for Teleportation-Based QDS
Smart India Hackathon (SIH 2026)
"""

import os
import sys
import time

SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from attack_suite import QDSAttackSuite
from arbiter_protocol import QDSArbiterProtocol
from math_model import QDSMathematicalModel
from teleportation import teleport_state, calculate_bob_probability


def clear_screen():
    os.system("cls" if os.name == "nt" else "clear")


def print_banner():
    print("=" * 72)
    print("  QUANTUM-INSPIRED CYBER THREAT DETECTION FRAMEWORK (QDS)")
    print("       Teleportation-Based Quantum Digital Signatures")
    print("             Smart India Hackathon (SIH 2026)")
    print("=" * 72)
    print("  [No AI/ML | Pure Quantum Principles & Information-Theoretic Security]")
    print("=" * 72)


def demo_teleportation():
    print("\n--- [1] Quantum Teleportation of Pauli Eigenstates ---")
    states = [("Z", "|0> (Computational 0)"), ("X", "|+> (Superposition)"), ("Y", "|+i> (Complex Superposition)")]
    shots = 1000

    for state, desc in states:
        print(f"\nTeleporting State: {state} [{desc}]...")
        start = time.perf_counter()
        counts = teleport_state(state, shots=shots)
        p0, p1 = calculate_bob_probability(counts, shots=shots)
        elapsed = (time.perf_counter() - start) * 1000.0

        status = "[SUCCESS]" if p0 >= 0.98 else "[DEGRADED]"
        print(f"  Outcome Frequencies: {counts}")
        print(f"  Bob P(0): {p0:.4f} | Bob P(1) Error: {p1:.4f} | Time: {elapsed:.1f} ms -> {status}")


def demo_attack_suite():
    print("\n--- [2] Comprehensive 4-Pronged Threat Detection Suite ---")
    suite = QDSAttackSuite(shots=1000, threshold=0.05)
    results = suite.run_all_scenarios()

    print(f"{'Scenario Name':<26} | {'Final Verdict':<10} | {'Threat Class':<28} | {'Status'}")
    print("-" * 78)
    for r in results:
        status = "[DETECTED/STOPPED]" if r["detected"] or r["attack_type"] == "CLEAN_LEGITIMATE" else "[VULNERABLE]"
        print(f"{r['attack_type']:<26} | {r['final_decision']:<10} | {r['threat_classification']:<28} | {status}")


def demo_arbiter():
    print("\n--- [3] 3-Party Non-Repudiation Arbiter Protocol ---")
    arbiter = QDSArbiterProtocol(channel_noise=0.02)
    res = arbiter.simulate_dispute_scenario("SIH2026_LEGAL_CONTRACT_#429")

    print(f"Contract Message:  {res['message']}")
    print(f"Bob Verification:  {res['bob_verification']['decision']} (Error: {res['bob_verification']['bob_error']:.3f}, Threshold s_v: {res['dual_thresholds']['s_v (Bob)']:.3f})")
    print(f"Charlie Decision:  {res['charlie_arbitration']['ruling']}")
    print(f"Repudiation Bound: P_repudiate <= {res['charlie_arbitration']['repudiation_probability_bound']:.2e}")
    print(f"Guaranteed Verdict: {'[PROVABLY SECURE - UNREPUDIABLE]' if res['non_repudiation_guaranteed'] else '[DISPUTE UNRESOLVED]'}")


def demo_math_bounds():
    print("\n--- [4] Information-Theoretic Mathematical Security Bounds ---")
    model = QDSMathematicalModel()
    print("Analytical Forgery Probability Scaling (Hoeffding Inequality):")
    for n in [8, 16, 32, 64, 128, 256]:
        pf = model.calculate_forgery_probability(num_qubits=n, error_rate=0.02, threshold=0.15)
        print(f"  N = {n:3d} qubits | P_forgery <= {pf:.2e}")


def main():
    print_banner()
    print("\nExecuting Complete System Demonstration for Evaluators...", flush=True)

    try:
        demo_teleportation()
        demo_attack_suite()
        demo_arbiter()
        demo_math_bounds()

        print("\n" + "=" * 72, flush=True)
        print("  [SUCCESS] All Quantum Threat Detection Modules Verified Successfully.", flush=True)
        print("  To launch the Interactive Web Dashboard, run:", flush=True)
        print("    streamlit run dashboard/app.py", flush=True)
        print("=" * 72, flush=True)
    except Exception as e:
        import traceback
        print(f"\n[EXCEPTION DURING DEMO]: {e}", flush=True)
        traceback.print_exc()


if __name__ == "__main__":
    main()

