from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error


def prepare_state(qc, state):
    if state == "Z":
        # |0> state
        pass

    elif state == "X":
        # |+> state
        qc.h(0)

    elif state == "Y":
        # |+i> state
        qc.h(0)
        qc.s(0)

    else:
        raise ValueError("State must be Z, X, or Y")


def apply_attack(qc, attack):
    if attack == "bit_flip":
        qc.x(0)

    elif attack == "phase_flip":
        qc.z(0)

    elif attack == "bit_phase_flip":
        qc.y(0)

    elif attack is None:
        pass

    else:
        raise ValueError("Unknown attack")


def measure_in_basis(qc, basis):
    if basis == "X":
        qc.h(0)

    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)

    elif basis == "Z":
        pass

    else:
        raise ValueError("Basis must be X, Y, or Z")

    qc.measure(0, 0)


def create_noise_model(noise_probability):
    noise_model = NoiseModel()

    # Depolarizing noise applied after the channel identity gate
    noise = depolarizing_error(noise_probability, 1)

    noise_model.add_quantum_error(
        noise,
        ["id"],
        [0]
    )

    return noise_model


def run_noisy_experiment(
    state,
    attack=None,
    noise_probability=0.02,
    shots=1000
):
    qc = QuantumCircuit(1, 1)

    # 1. Prepare quantum state
    prepare_state(qc, state)

    # 2. Apply possible channel attack
    apply_attack(qc, attack)

    # 3. Simulate channel noise
    # Noise is attached to this identity gate
    qc.id(0)

    # 4. Measure in matching Pauli basis
    measure_in_basis(qc, state)

    # 5. Create simulator
    simulator = AerSimulator()

    noise_model = create_noise_model(noise_probability)

    # optimization_level=0 keeps the identity gate
    result = simulator.run(
        qc,
        shots=shots,
        noise_model=noise_model,
        optimization_level=0
    ).result()

    return result.get_counts()


def calculate_statistics(counts, shots):
    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    # For matching basis, measurement result "1"
    # represents an unexpected result.
    error_rate = probability_1

    return probability_0, probability_1, error_rate


if __name__ == "__main__":
    print("========================================")
    print("     NOISY QUANTUM CHANNEL EXPERIMENT")
    print("========================================")

    states = ["Z", "X", "Y"]

    attacks = [
        None,
        "bit_flip",
        "phase_flip",
        "bit_phase_flip"
    ]

    shots = 1000
    noise_probability = 0.02

    print(f"\nDepolarizing Noise Parameter: {noise_probability}")
    print(f"Shots per experiment: {shots}")

    for state in states:

        print(f"\n{'=' * 40}")
        print(f"STATE: {state}-EIGENSTATE")
        print(f"{'=' * 40}")

        for attack in attacks:

            name = "LEGITIMATE" if attack is None else attack.upper()

            counts = run_noisy_experiment(
                state=state,
                attack=attack,
                noise_probability=noise_probability,
                shots=shots
            )

            p0, p1, error_rate = calculate_statistics(
                counts,
                shots
            )

            print(f"\n{name}")
            print("Measurement Results:", counts)
            print(f"P(0): {p0:.4f}")
            print(f"P(1): {p1:.4f}")
            print(f"Error Rate: {error_rate:.4f}")