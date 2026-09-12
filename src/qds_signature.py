import hashlib
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def message_to_state(message):
    """
    Deterministically map a message to one of the
    three Pauli eigenstates: Z, X, or Y.
    """

    digest = hashlib.sha256(message.encode()).hexdigest()

    value = int(digest[0], 16)

    states = ["Z", "X", "Y"]

    return states[value % 3]


def prepare_state(qc, state):
    """
    Prepare the +1 eigenstate of the selected
    Pauli operator.

    Z -> |0>
    X -> |+>
    Y -> |+i>
    """

    if state == "Z":
        # |0>
        pass

    elif state == "X":
        # |+> = H|0>
        qc.h(0)

    elif state == "Y":
        # |+i> = S H|0>
        qc.h(0)
        qc.s(0)

    else:
        raise ValueError("State must be Z, X, or Y")


def apply_measurement_basis(qc, state, qubit):
    """
    Rotate the selected Pauli eigenstate into the
    computational (Z) basis before measurement.

    Z basis: no rotation
    X basis: H
    Y basis: Sdg followed by H
    """

    if state == "Z":
        # Already in Z basis
        pass

    elif state == "X":
        # X-basis measurement
        qc.h(qubit)

    elif state == "Y":
        # Y-basis measurement
        qc.sdg(qubit)
        qc.h(qubit)

    else:
        raise ValueError("State must be Z, X, or Y")


def generate_signature(message, shots=1000):

    message_hash = hashlib.sha256(
        message.encode()
    ).hexdigest()

    state = message_to_state(message)

    # ------------------------------------------------
    # 3 qubits
    #
    # q0 -> message/signing state
    # q1,q2 -> Bell pair
    # ------------------------------------------------

    qc = QuantumCircuit(3, 3)

    # ------------------------------------------------
    # 1. Prepare message quantum state
    # ------------------------------------------------

    prepare_state(qc, state)

    # ------------------------------------------------
    # 2. Create Bell pair
    # ------------------------------------------------

    qc.h(1)
    qc.cx(1, 2)

    # ------------------------------------------------
    # 3. Alice's teleportation operations
    # ------------------------------------------------

    qc.cx(0, 1)
    qc.h(0)

    # ------------------------------------------------
    # 4. Measure Alice's two qubits
    # ------------------------------------------------

    qc.measure(0, 0)
    qc.measure(1, 1)

    # ------------------------------------------------
    # 5. Bob's Pauli corrections
    # ------------------------------------------------

    # X correction controlled by Alice's second bit
    with qc.if_test((qc.clbits[1], 1)):
        qc.x(2)

    # Z correction controlled by Alice's first bit
    with qc.if_test((qc.clbits[0], 1)):
        qc.z(2)

    # ------------------------------------------------
    # 6. Apply correct projective measurement basis
    # ------------------------------------------------

    apply_measurement_basis(qc, state, 2)

    # ------------------------------------------------
    # 7. Measure Bob's qubit
    # ------------------------------------------------

    qc.measure(2, 2)

    # ------------------------------------------------
    # 8. Run simulation
    # ------------------------------------------------

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    counts = result.get_counts()

    return {
        "message": message,
        "message_hash": message_hash,
        "quantum_state": state,
        "measurement_basis": state,
        "expected_outcome": "0",
        "measurement_results": counts,
        "shots": shots
    }


# --------------------------------------------------
# TEST
# --------------------------------------------------

if __name__ == "__main__":

    message = "SIH26141"

    signature = generate_signature(message)

    print("===== QDS SIGNATURE GENERATION =====")

    print("\nMessage:")
    print(signature["message"])

    print("\nMessage Hash:")
    print(signature["message_hash"])

    print("\nQuantum State:")
    print(signature["quantum_state"])

    print("\nMeasurement Basis:")
    print(signature["measurement_basis"])

    print("\nExpected Measurement Outcome:")
    print(signature["expected_outcome"])

    print("\nMeasurement Results:")
    print(signature["measurement_results"])

    print("\nShots:")
    print(signature["shots"])