"""
Automated Benchmarking Engine for Quantum-Inspired QDS Threat Detection
Evaluates TPR, FPR, Precision, Recall, F1, Latency across various channel noise levels.
Smart India Hackathon 2026
"""

import os
import sys
import time
import csv
from typing import List, Dict, Any

# Ensure src is in sys.path
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from attack_suite import QDSAttackSuite
from math_model import QDSMathematicalModel

OUTPUT_CSV = os.path.join(os.path.dirname(__file__), "..", "data", "sih_benchmark_results.csv")


def execute_comprehensive_benchmark(trials_per_scenario: int = 5) -> List[Dict[str, Any]]:
    suite = QDSAttackSuite(shots=1000, threshold=0.05)
    records = []

    print(f"Starting QDS Threat Detection Benchmark ({trials_per_scenario} trials per scenario)...")
    
    scenarios = [
        ("CLEAN_LEGITIMATE", lambda: suite.run_clean_scenario("AUTHORIZED_DATA_PACKET"), False),
        ("SIGNATURE_FORGERY", lambda: suite.run_forgery_attack("TRANSFER_100", "TRANSFER_99999"), True),
        ("IMPERSONATION", lambda: suite.run_impersonation_attack("FORGED_SENDER_IDENTITY"), True),
        ("REPLAY_ATTACK", lambda: suite.run_replay_attack("REPLAYED_COMMAND_TRANSACTION"), True),
        ("CHANNEL_BIT_FLIP", lambda: suite.run_channel_manipulation("Z", "bit_flip", 0.05), True),
        ("CHANNEL_PHASE_FLIP", lambda: suite.run_channel_manipulation("X", "phase_flip", 0.05), True),
    ]

    for scenario_name, runner, is_attack in scenarios:
        for trial in range(1, trials_per_scenario + 1):
            suite.reset_replay_cache()
            start = time.perf_counter()
            res = runner()
            elapsed_ms = (time.perf_counter() - start) * 1000.0

            detected = res.get("detected", False)
            decision = res.get("final_decision", "UNKNOWN")

            # Ground truth classification
            if not is_attack and decision == "ACCEPT":
                eval_class = "TRUE_NEGATIVE"   # Correctly accepted legitimate
            elif not is_attack and decision == "REJECT":
                eval_class = "FALSE_POSITIVE"  # Incorrectly rejected legitimate
            elif is_attack and decision == "REJECT":
                eval_class = "TRUE_POSITIVE"   # Correctly rejected attack
            else:
                eval_class = "FALSE_NEGATIVE"  # Failed to reject attack

            record = {
                "trial_id": f"{scenario_name}_{trial}",
                "scenario": scenario_name,
                "is_attack": is_attack,
                "detected": detected,
                "final_decision": decision,
                "eval_classification": eval_class,
                "latency_ms": round(elapsed_ms, 2),
                "error_rate": round(res.get("error_rate", 0.0), 4),
                "threat_classification": res.get("threat_classification", "NONE"),
            }
            records.append(record)
            print(f"  [{scenario_name:<20} | Trial {trial}] -> {eval_class} ({elapsed_ms:.1f} ms)")

    # Save to CSV
    os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)
    if records:
        keys = records[0].keys()
        with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(records)

    print(f"\n[OK] Benchmark completed. Results saved to: {OUTPUT_CSV}")
    
    # Compute summary metrics
    tp = sum(1 for r in records if r["eval_classification"] == "TRUE_POSITIVE")
    tn = sum(1 for r in records if r["eval_classification"] == "TRUE_NEGATIVE")
    fp = sum(1 for r in records if r["eval_classification"] == "FALSE_POSITIVE")
    fn = sum(1 for r in records if r["eval_classification"] == "FALSE_NEGATIVE")
    
    precision = tp / (tp + fp) if (tp + fp) > 0 else 1.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 1.0
    accuracy = (tp + tn) / len(records) if records else 1.0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 1.0

    print("\n==========================================")
    print("       BENCHMARK EVALUATION SUMMARY       ")
    print("==========================================")
    print(f"  Total Experiments:  {len(records)}")
    print(f"  True Positives:     {tp}")
    print(f"  True Negatives:     {tn}")
    print(f"  False Positives:    {fp}")
    print(f"  False Negatives:    {fn}")
    print(f"  Accuracy:           {accuracy * 100:.2f}%")
    print(f"  Precision:          {precision * 100:.2f}%")
    print(f"  Recall (TPR):       {recall * 100:.2f}%")
    print(f"  F1 Score:           {f1:.4f}")
    print("==========================================")

    return records


if __name__ == "__main__":
    execute_comprehensive_benchmark(trials_per_scenario=5)
