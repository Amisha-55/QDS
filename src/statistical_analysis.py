from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def prepare_state(qc, state):
    if state == "Z":
        pass

    elif state == "X":
        qc.h(0)

    elif state == "Y":
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


def run_experiment(state, attack=None, shots=1000):

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    apply_attack(qc, attack)

    measure_in_basis(qc, state)

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    return result.get_counts()


def calculate_statistics(counts, shots):

    zero_count = counts.get("0", 0)
    one_count = counts.get("1", 0)

    probability_0 = zero_count / shots
    probability_1 = one_count / shots

    error_rate = probability_1

    return probability_0, probability_1, error_rate


print("========================================")
print("     STATISTICAL CHANNEL ANALYSIS")
print("========================================")

states = ["Z", "X", "Y"]
attacks = [
    None,
    "bit_flip",
    "phase_flip",
    "bit_phase_flip"
]

shots = 1000


for state in states:

    print(f"\n{'=' * 40}")
    print(f"STATE: {state}-EIGENSTATE")
    print(f"{'=' * 40}")

    for attack in attacks:

        name = "LEGITIMATE" if attack is None else attack.upper()

        counts = run_experiment(
            state=state,
            attack=attack,
            shots=shots
        )

        p0, p1, error_rate = calculate_statistics(
            counts,
            shots
        )

        print(f"\n{name}")
        print("Measurement:", counts)
        print(f"P(0): {p0:.3f}")
        print(f"P(1): {p1:.3f}")
        print(f"Error Rate: {error_rate:.3f}")