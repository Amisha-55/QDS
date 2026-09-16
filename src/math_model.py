"""
Mathematical Formulation & Information-Theoretic Security Engine for Teleportation-Based QDS

Provides:
1. Information-Theoretic Forgery Probability Bounds (P_forgery <= 2^{-alpha * N})
2. Trace Distance and Quantum State Fidelity Metrics
3. Chernoff-Hoeffding Statistical Confidence Bounds
4. Optimal Verification & Repudiation Threshold Calibration (s_a, s_v)
5. Eavesdropping Detection Likelihood Ratio Test (LRT)
"""

import math
from typing import Dict, Tuple, Any


class QDSMathematicalModel:
    """
    Theoretical security model grounding the QDS threat detection
    framework in quantum mechanics and statistical decision theory.
    Strictly non-AI/ML.
    """

    def __init__(self, default_noise_rate: float = 0.02, significance_alpha: float = 0.01):
        self.p_channel = default_noise_rate
        self.alpha = significance_alpha

    # -------------------------------------------------------------
    # 1. FORGERY PROBABILITY BOUNDS
    # -------------------------------------------------------------
    @staticmethod
    def calculate_forgery_probability(
        num_qubits: int,
        error_rate: float,
        threshold: float
    ) -> float:
        """
        Derives analytical upper bound on forgery probability under
        the quantum no-cloning theorem and mutually unbiased bases (MUBs).

        If an attacker (Eve or Bob) attempts to forge a signature without
        knowing the secret Pauli bases {X, Y, Z}, measuring in the wrong
        basis yields an error probability of 0.5 per bit.

        By Hoeffding's Inequality:
            P_forgery <= exp( -2 * N * (threshold - error_rate)^2 )

        Returns probability in range [0.0, 1.0].
        """
        if num_qubits <= 0:
            return 1.0

        if error_rate >= threshold:
            return 1.0

        delta = threshold - error_rate
        exponent = -2.0 * num_qubits * (delta ** 2)

        # Prevent underflow
        if exponent < -700:
            return 0.0

        return float(math.exp(exponent))

    # -------------------------------------------------------------
    # 2. CHERNOFF-HOEFFDING ERROR MARGINS
    # -------------------------------------------------------------
    @staticmethod
    def calculate_confidence_interval(
        observed_error: float,
        shots: int,
        confidence_level: float = 0.99
    ) -> Tuple[float, float, float]:
        """
        Calculates conservative confidence interval for error rate
        using Hoeffding's bound without assuming Gaussian distribution:

            margin = sqrt( ln(2 / (1 - confidence_level)) / (2 * shots) )

        Returns: (lower_bound, upper_bound, margin)
        """
        if shots <= 0:
            return (0.0, 1.0, 1.0)

        delta = 1.0 - confidence_level
        margin = math.sqrt(math.log(2.0 / delta) / (2.0 * shots))

        lower = max(0.0, observed_error - margin)
        upper = min(1.0, observed_error + margin)

        return lower, upper, margin

    # -------------------------------------------------------------
    # 3. STATISTICAL HYPOTHESIS TESTING (LRT)
    # -------------------------------------------------------------
    @staticmethod
    def likelihood_ratio_test(
        zero_count: int,
        one_count: int,
        shots: int,
        p_legitimate: float = 0.02,
        p_attack: float = 0.50
    ) -> Dict[str, Any]:
        """
        Binary hypothesis testing:
            H0 (Legitimate): p_error <= p_legitimate (channel noise)
            H1 (Attack/Tampering): p_error >= p_attack (measurement in wrong basis)

        Computes log-likelihood ratio:
            LLR = sum log( P(k | H1) / P(k | H0) )
        """
        k = one_count
        n = shots

        # Avoid log(0)
        eps = 1e-9
        p0 = min(max(p_legitimate, eps), 1.0 - eps)
        p1 = min(max(p_attack, eps), 1.0 - eps)

        # Log Likelihood under H0 and H1
        log_l0 = k * math.log(p0) + (n - k) * math.log(1.0 - p0)
        log_l1 = k * math.log(p1) + (n - k) * math.log(1.0 - p1)
        llr = log_l1 - log_l0

        decision = "ATTACK" if llr > 0 else "LEGITIMATE"
        p_val = math.exp(-abs(llr)) if abs(llr) < 700 else 0.0

        return {
            "llr": llr,
            "decision": decision,
            "p_value": p_val,
            "observed_error": k / n if n > 0 else 1.0,
            "h0_prob": p0,
            "h1_prob": p1
        }

    # -------------------------------------------------------------
    # 4. QUANTUM FIDELITY & TRACE DISTANCE
    # -------------------------------------------------------------
    @staticmethod
    def quantum_state_fidelity(counts: Dict[str, int], shots: int, expected_state: str = "0") -> float:
        """
        Calculates quantum fidelity F = <psi_expected | rho | psi_expected>
        from projective measurement counts.
        """
        if shots <= 0:
            return 0.0
        return counts.get(expected_state, 0) / shots

    @staticmethod
    def trace_distance_bound(fidelity: float) -> float:
        """
        Relates quantum fidelity F to trace distance D:
            1 - sqrt(F) <= D(rho, sigma) <= sqrt(1 - F)
        """
        f = min(max(fidelity, 0.0), 1.0)
        upper_bound = math.sqrt(1.0 - f)
        return upper_bound

    # -------------------------------------------------------------
    # 5. DUAL-THRESHOLD NON-REPUDIATION CALIBRATION (Arbiter)
    # -------------------------------------------------------------
    @staticmethod
    def calculate_sih_dual_thresholds(
        channel_error: float = 0.03,
        safety_margin: float = 0.10
    ) -> Tuple[float, float]:
        """
        Calculates dual thresholds for the 3-party QDS protocol:
            s_v: Verification threshold for Bob (accept if error <= s_v)
            s_a: Arbiter threshold for Charlie (adjudicate if error <= s_a)

        Security conditions for Non-Repudiation:
            channel_error < s_v < s_a < 0.50

        If Bob accepts (error <= s_v), Alice cannot successfully repudiate
        to Charlie because Bob can forward states that satisfy Charlie's
        looser threshold s_a with probability 1 - 2^{-O(N)}.
        """
        s_v = channel_error + safety_margin
        s_a = s_v + safety_margin

        # Ensure bounds
        s_v = min(s_v, 0.25)
        s_a = min(s_a, 0.40)

        return s_v, s_a


if __name__ == "__main__":
    model = QDSMathematicalModel()
    print("=== QDS Mathematical Bounds Demonstration ===")
    for n in [8, 16, 32, 64, 128]:
        p_f = model.calculate_forgery_probability(num_qubits=n, error_rate=0.03, threshold=0.15)
        print(f"N={n:3d} qubits | P_forgery <= {p_f:.2e}")
