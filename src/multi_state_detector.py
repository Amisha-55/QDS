from noisy_channel import run_noisy_experiment
from config import (
    NOISE_PROBABILITY,
    NOISE_THRESHOLDS,
    SHOTS,
    STATES,
    BASES
)


# ============================================
# EXPECTED MEASUREMENT BEHAVIOR
# ============================================

def expected_probability_one(state, basis):
    """
    Return the expected P(1) for a Pauli eigenstate
    measured in a particular Pauli basis.

    Matching basis:
        P(1) = 0

    Different basis:
        P(1) = 0.5
    """

    if state == basis:
        return 0.0

    return 0.5


# ============================================
# CROSS-BASIS DEVIATION
# ============================================

def calculate_deviation(observed_p1, expected_p1):
    """
    Calculate the absolute deviation between
    observed and expected P(1).
    """

    return abs(observed_p1 - expected_p1)


# ============================================
# NOISE-AWARE THRESHOLD
# ============================================

def get_threshold(noise_probability):
    """
    Return the calibrated threshold for the
    requested noise probability.

    The exact calibrated value is used when
    available.
    """

    if noise_probability in NOISE_THRESHOLDS:
        return NOISE_THRESHOLDS[noise_probability]

    raise ValueError(
        f"No calibrated threshold available for "
        f"noise probability {noise_probability}"
    )


# ============================================
# MULTI-STATE THREAT DETECTION
# ============================================

def run_multi_state_test(
    attack=None,
    shots=SHOTS,
    noise_probability=NOISE_PROBABILITY
):
    """
    Run Z, X and Y states across Z, X and Y
    measurement bases.

    The detector calculates an aggregate
    cross-basis deviation score.
    """

    threshold = get_threshold(noise_probability)

    total_deviation = 0.0
    experiment_count = 0

    state_results = {}

    for state in STATES:

        state_results[state] = {}

        for basis in BASES:

            counts = run_noisy_experiment(
                state=state,
                attack=attack,
                noise_probability=noise_probability,
                shots=shots,
                measurement_basis=basis
            )

            zero_count = counts.get("0", 0)
            one_count = counts.get("1", 0)

            probability_0 = zero_count / shots
            probability_1 = one_count / shots

            expected_p1 = expected_probability_one(
                state,
                basis
            )

            deviation = calculate_deviation(
                probability_1,
                expected_p1
            )

            total_deviation += deviation
            experiment_count += 1

            state_results[state][basis] = {
                "counts": counts,
                "probability_0": probability_0,
                "probability_1": probability_1,
                "expected_p1": expected_p1,
                "deviation": deviation
            }

    aggregate_score = (
        total_deviation / experiment_count
    )

    if aggregate_score <= threshold:
        decision = "LEGITIMATE"
    else:
        decision = "SUSPICIOUS / ATTACK"

    return (
        state_results,
        aggregate_score,
        threshold,
        decision
    )


# ============================================
# TEST PROGRAM
# ============================================

if __name__ == "__main__":

    print("========================================")
    print("   NOISE-AWARE QDS THREAT DETECTOR")
    print("========================================")

    print(f"\nShots: {SHOTS}")
    print(f"Noise Probability: {NOISE_PROBABILITY}")

    attacks = [
        None,
        "bit_flip",
        "phase_flip",
        "bit_phase_flip"
    ]

    for attack in attacks:

        print("\n----------------------------------------")

        if attack is None:
            print("TEST: LEGITIMATE")
        else:
            print(f"TEST: {attack.upper()}")

        (
            state_results,
            aggregate_score,
            threshold,
            decision
        ) = run_multi_state_test(
            attack=attack,
            shots=SHOTS,
            noise_probability=NOISE_PROBABILITY
        )

        for state in STATES:

            for basis in BASES:

                result = state_results[state][basis]

                print(
                    f"{state} STATE → {basis} BASIS | "
                    f"P(1)={result['probability_1']:.3f} | "
                    f"Expected={result['expected_p1']:.3f} | "
                    f"Deviation={result['deviation']:.3f}"
                )

        print(
            f"\nAggregate Deviation Score: "
            f"{aggregate_score:.4f}"
        )

        print(
            f"Noise-Aware Threshold: "
            f"{threshold:.4f}"
        )

        print(f"Decision: {decision}")