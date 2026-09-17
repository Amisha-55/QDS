from config import THRESHOLD, SHOTS


def detect_threat(error_rate, threshold=THRESHOLD):
    """
    Detect whether a quantum measurement result
    is within the legitimate error range.
    """

    if error_rate <= threshold:
        return "LEGITIMATE"
    else:
        return "SUSPICIOUS / ATTACK"


def calculate_error_rate(counts, shots):
    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    error_rate = probability_1

    return probability_0, probability_1, error_rate


def comprehensive_threat_classification(counts, shots, threshold=THRESHOLD, num_qubits=8, p_expected_noise=0.02):
    """
    Non-AI/ML threat classification based on:
    1. Hoeffding statistical confidence intervals.
    2. Likelihood Ratio Test (LRT) against interception hypothesis.
    3. Quantum state fidelity and trace distance bounds.
    4. Information-theoretic forgery upper bound.
    """
    from math_model import QDSMathematicalModel
    
    p0, p1, error_rate = calculate_error_rate(counts, shots)
    fidelity = QDSMathematicalModel.quantum_state_fidelity(counts, shots, expected_state="0")
    trace_dist = QDSMathematicalModel.trace_distance_bound(fidelity)
    
    ci_lower, ci_upper, margin = QDSMathematicalModel.calculate_confidence_interval(
        observed_error=error_rate, shots=shots, confidence_level=0.99
    )
    
    lrt = QDSMathematicalModel.likelihood_ratio_test(
        zero_count=counts.get("0", 0),
        one_count=counts.get("1", 0),
        shots=shots,
        p_legitimate=p_expected_noise,
        p_attack=0.50
    )
    
    p_forgery = QDSMathematicalModel.calculate_forgery_probability(
        num_qubits=num_qubits,
        error_rate=error_rate,
        threshold=threshold
    )
    
    # Non-AI Classification Logic
    if error_rate <= threshold:
        threat_type = "NONE"
        status = "LEGITIMATE"
        threat_severity = "LOW"
    elif error_rate >= 0.85:
        threat_type = "ACTIVE_PAULI_BIT_FLIP"
        status = "CRITICAL_ATTACK"
        threat_severity = "HIGH"
    elif 0.40 <= error_rate <= 0.60:
        threat_type = "INTERCEPT_RESEND_OR_DEPOLARIZING"
        status = "EAVESDROPPING_DETECTED"
        threat_severity = "CRITICAL"
    else:
        threat_type = "ANOMALOUS_CHANNEL_NOISE"
        status = "SUSPICIOUS"
        threat_severity = "MEDIUM"
        
    return {
        "status": status,
        "threat_type": threat_type,
        "threat_severity": threat_severity,
        "error_rate": error_rate,
        "fidelity": fidelity,
        "trace_distance_bound": trace_dist,
        "threshold": threshold,
        "forgery_probability": p_forgery,
        "llr": lrt["llr"],
        "llr_decision": lrt["decision"],
        "confidence_interval_99": (ci_lower, ci_upper),
        "ci_margin": margin,
        "shots": shots
    }


if __name__ == "__main__":

    print("========================================")
    print("       STATISTICAL THREAT DETECTOR")
    print("========================================")

    shots = SHOTS

    legitimate_counts = {"0": 988, "1": 12}

    p0, p1, legitimate_error = calculate_error_rate(
        legitimate_counts,
        shots
    )

    legitimate_decision = detect_threat(legitimate_error)

    print("\nLEGITIMATE TEST")
    print("Measurement Results:", legitimate_counts)
    print(f"P(0): {p0:.3f}")
    print(f"P(1): {p1:.3f}")
    print(f"Error Rate: {legitimate_error:.3f}")
    print(f"Threshold: {THRESHOLD:.4f}")
    print("Decision:", legitimate_decision)


    attack_counts = {"0": 12, "1": 988}

    p0, p1, attack_error = calculate_error_rate(
        attack_counts,
        shots
    )

    attack_decision = detect_threat(attack_error)

    print("\nATTACK TEST")
    print("Measurement Results:", attack_counts)
    print(f"P(0): {p0:.3f}")
    print(f"P(1): {p1:.3f}")
    print(f"Error Rate: {attack_error:.3f}")
    print(f"Threshold: {THRESHOLD:.4f}")
    print("Decision:", attack_decision)