
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
from qiskit_aer.noise import NoiseModel, depolarizing_error


def prepare_state(qc, state):
    """
    Prepare a Pauli eigenstate.

    Z -> |0>
    X -> |+>
    Y -> |+i>
    """

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
    """
    Apply a simulated Pauli attack.
    """

    if attack is None:
        return

    elif attack == "bit_flip":
        qc.x(0)

    elif attack == "phase_flip":
        qc.z(0)

    elif attack == "bit_phase_flip":
        qc.y(0)

    else:
        raise ValueError(f"Unknown attack: {attack}")


def apply_measurement_basis(qc, basis):
    """
    Convert the selected Pauli measurement basis
    into the computational Z basis.
    """

    if basis == "Z":
        pass

    elif basis == "X":
        qc.h(0)

    elif basis == "Y":
        qc.sdg(0)
        qc.h(0)

    else:
        raise ValueError("Basis must be Z, X, or Y")


def run_noisy_experiment(
    state,
    attack=None,
    noise_probability=0.02,
    shots=1000,
    measurement_basis="Z"
):
    """
    Prepare a Pauli eigenstate, optionally apply
    a Pauli attack, pass through a depolarizing
    channel, and measure in the selected basis.
    """

    qc = QuantumCircuit(1, 1)

    prepare_state(qc, state)

    apply_attack(qc, attack)

    qc.id(0)

    apply_measurement_basis(
        qc,
        measurement_basis
    )

    qc.measure(0, 0)

    noise_model = NoiseModel()

    if noise_probability > 0:

        error = depolarizing_error(
            noise_probability,
            1
        )

        noise_model.add_all_qubit_quantum_error(
            error,
            ["id"]
        )

    simulator = AerSimulator(
        noise_model=noise_model
    )

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    return result.get_counts()


if __name__ == "__main__":

    print("========================================")
    print("   NOISY QUANTUM CHANNEL EXPERIMENT")
    print("========================================")

    noise_probability = 0.02
    shots = 1000

    print(
        f"\nDepolarizing Noise Parameter: "
        f"{noise_probability}"
    )

    print(f"Shots per experiment: {shots}")

    states = ["Z", "X", "Y"]
    bases = ["Z", "X", "Y"]

    attacks = [
        None,
        "bit_flip",
        "phase_flip",
        "bit_phase_flip"
    ]

    for attack in attacks:

        print("\n========================================")

        if attack is None:
            print("ATTACK: LEGITIMATE")
        else:
            print(f"ATTACK: {attack.upper()}")

        print("========================================")

        for state in states:

            print(f"\nSTATE: {state}-EIGENSTATE")

            for basis in bases:

                counts = run_noisy_experiment(
                    state=state,
                    attack=attack,
                    noise_probability=noise_probability,
                    shots=shots,
                    measurement_basis=basis
                )

                zero_count = counts.get("0", 0)
                one_count = counts.get("1", 0)

                p0 = zero_count / shots
                p1 = one_count / shots

                print(
                    f"{state} → {basis} | "
                    f"P(0)={p0:.3f} | "
                    f"P(1)={p1:.3f} | "
                    f"{counts}"
                )