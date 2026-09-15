from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def prepare_state(qc, state):
    """
    Prepare one of the three +1 Pauli eigenstates.

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


def apply_measurement_basis(qc, state):
    """
    Rotate Bob's qubit into the computational basis
    for measurement in the selected Pauli basis.

    Z basis -> no rotation
    X basis -> H
    Y basis -> Sdg followed by H
    """

    if state == "Z":
        pass

    elif state == "X":
        qc.h(2)

    elif state == "Y":
        qc.sdg(2)
        qc.h(2)

    else:
        raise ValueError("State must be Z, X, or Y")


def create_bell_pair(qc):
    """
    Create the Bell state

        |Φ+> = (|00> + |11>) / sqrt(2)

    using q1 and q2.
    """

    qc.h(1)
    qc.cx(1, 2)


def teleport_state(state, shots=1000):
    """
    Teleport a selected Pauli eigenstate from q0 to q2.

    Qubits:
        q0 -> original state
        q1 -> Alice's Bell-pair qubit
        q2 -> Bob's Bell-pair qubit

    Classical bits:
        c0 -> measurement of q0
        c1 -> measurement of q1
        c2 -> Bob's final measurement
    """

    if state not in ["Z", "X", "Y"]:
        raise ValueError("State must be Z, X, or Y")

    if shots <= 0:
        raise ValueError("Shots must be greater than zero")

    qc = QuantumCircuit(3, 3)

    prepare_state(qc, state)

    create_bell_pair(qc)

    qc.cx(0, 1)
    qc.h(0)

    qc.measure(0, 0)
    qc.measure(1, 1)

    with qc.if_test((qc.clbits[1], 1)):
        qc.x(2)

    with qc.if_test((qc.clbits[0], 1)):
        qc.z(2)

    apply_measurement_basis(qc, state)

    qc.measure(2, 2)

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    return result.get_counts()


def calculate_bob_probability(counts, shots):
    """
    Calculate Bob's P(0) and P(1).

    Qiskit displays classical bits as c2 c1 c0.
    Therefore, Bob's measurement c2 is the leftmost bit.
    """

    bob_zero = 0
    bob_one = 0

    for result, count in counts.items():

        bob_bit = result[0]

        if bob_bit == "0":
            bob_zero += count
        else:
            bob_one += count

    probability_zero = bob_zero / shots
    probability_one = bob_one / shots

    return probability_zero, probability_one


if __name__ == "__main__":

    shots = 1000

    print("========================================")
    print("       QUANTUM TELEPORTATION TEST")
    print("========================================")

    for state in ["Z", "X", "Y"]:

        counts = teleport_state(
            state,
            shots
        )

        probability_zero, probability_one = (
            calculate_bob_probability(
                counts,
                shots
            )
        )

        print("\n----------------------------------------")
        print(f"STATE TELEPORTED: {state}")

        print("Measurement Results:")
        print(counts)

        print(
            f"Bob P(0): "
            f"{probability_zero:.3f}"
        )

        print(
            f"Bob P(1): "
            f"{probability_one:.3f}"
        )

        if probability_zero >= 0.99:

            print(
                "Teleportation Result: SUCCESS"
            )

        else:

            print(
                "Teleportation Result: CHECK"
            )

    print("\n========================================")
    print("       TELEPORTATION TEST COMPLETE")
    print("========================================")