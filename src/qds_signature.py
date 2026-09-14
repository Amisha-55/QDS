import hashlib
import uuid
from datetime import datetime

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


# ============================================================
# MESSAGE → QUANTUM STATE
# ============================================================

def message_to_state(message):
    """
    Deterministically map a message to one of the
    three +1 Pauli eigenstates.

    Z -> |0>
    X -> |+>
    Y -> |+i>
    """

    digest = hashlib.sha256(
        message.encode()
    ).hexdigest()

    value = int(digest[0], 16)

    states = ["Z", "X", "Y"]

    return states[value % len(states)]


# ============================================================
# QUANTUM STATE PREPARATION
# ============================================================

def prepare_state(qc, state, qubit=0):
    """
    Prepare the +1 eigenstate of the selected
    Pauli operator.

    Z -> |0>
    X -> |+>
    Y -> |+i>
    """

    if state == "Z":

        # |0> is already the initial state.
        pass

    elif state == "X":

        # |+> = H|0>
        qc.h(qubit)

    elif state == "Y":

        # |+i> = S|+> = S H|0>
        qc.h(qubit)
        qc.s(qubit)

    else:

        raise ValueError(
            "State must be Z, X, or Y"
        )


# ============================================================
# MEASUREMENT BASIS
# ============================================================

def apply_measurement_basis(
    qc,
    basis,
    qubit
):
    """
    Rotate a qubit so that measurement in the
    computational Z basis becomes measurement
    in the requested Pauli basis.

    Z basis:
        No rotation

    X basis:
        H

    Y basis:
        Sdg followed by H
    """

    if basis == "Z":

        pass

    elif basis == "X":

        qc.h(qubit)

    elif basis == "Y":

        qc.sdg(qubit)
        qc.h(qubit)

    else:

        raise ValueError(
            "Basis must be Z, X, or Y"
        )


# ============================================================
# BELL-STATE CREATION
# ============================================================

def create_bell_pair(qc):
    """
    Create a Bell pair using qubits 1 and 2.

    |Φ+> = (|00> + |11>) / sqrt(2)
    """

    qc.h(1)
    qc.cx(1, 2)


# ============================================================
# TELEPORTATION
# ============================================================

def teleport_state(qc):
    """
    Teleport the state on qubit 0 to qubit 2.

    Qubits:
        q0 -> original quantum state
        q1 -> Alice's Bell-pair qubit
        q2 -> Bob's Bell-pair qubit

    Classical bits:
        c0 -> first Bell measurement result
        c1 -> second Bell measurement result
    """

    # Alice performs the Bell-state measurement
    # operations on q0 and q1.

    qc.cx(0, 1)
    qc.h(0)

    # Measure Alice's two qubits.

    qc.measure(0, 0)
    qc.measure(1, 1)

    # --------------------------------------------------------
    # Pauli corrections at Bob
    # --------------------------------------------------------

    # If Alice's second measurement bit is 1:
    # apply X correction.

    with qc.if_test(
        (qc.clbits[1], 1)
    ):
        qc.x(2)

    # If Alice's first measurement bit is 1:
    # apply Z correction.

    with qc.if_test(
        (qc.clbits[0], 1)
    ):
        qc.z(2)


# ============================================================
# SIGNATURE GENERATION
# ============================================================

def generate_signature(
    message,
    shots=1000
):
    """
    Generate a simulated teleportation-based
    quantum digital signature.

    This is a simulation/prototype model and
    not a production cryptographic signature.
    """

    if not isinstance(message, str):

        raise TypeError(
            "Message must be a string"
        )

    if not message:

        raise ValueError(
            "Message cannot be empty"
        )

    if shots <= 0:

        raise ValueError(
            "Shots must be greater than zero"
        )

    # --------------------------------------------------------
    # Classical message hash
    # --------------------------------------------------------

    message_hash = hashlib.sha256(
        message.encode()
    ).hexdigest()

    # --------------------------------------------------------
    # Deterministic quantum-state representation
    # --------------------------------------------------------

    state = message_to_state(message)

    # --------------------------------------------------------
    # Create 3-qubit circuit
    #
    # q0 -> message/signing state
    # q1 -> Alice's Bell qubit
    # q2 -> Bob's Bell qubit
    #
    # c0 -> q0 measurement
    # c1 -> q1 measurement
    # c2 -> Bob's final measurement
    # --------------------------------------------------------

    qc = QuantumCircuit(3, 3)

    # --------------------------------------------------------
    # 1. Prepare quantum state
    # --------------------------------------------------------

    prepare_state(
        qc,
        state,
        qubit=0
    )

    # --------------------------------------------------------
    # 2. Create Bell pair
    # --------------------------------------------------------

    create_bell_pair(qc)

    # --------------------------------------------------------
    # 3. Teleport state
    # --------------------------------------------------------

    teleport_state(qc)

    # --------------------------------------------------------
    # 4. Measure Bob's reconstructed state
    #
    # The state was encoded as a Pauli eigenstate,
    # therefore the matching basis should produce
    # the +1 eigenstate result, represented here
    # by computational outcome 0.
    # --------------------------------------------------------

    apply_measurement_basis(
        qc,
        state,
        qubit=2
    )

    qc.measure(2, 2)

    # --------------------------------------------------------
    # 5. Run quantum simulation
    # --------------------------------------------------------

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    counts = result.get_counts()

    # --------------------------------------------------------
    # 6. Create signature record
    # --------------------------------------------------------

    signature = {

        "signature_id":
            str(uuid.uuid4()),

        "timestamp":
            datetime.now().isoformat(),

        "protocol":
            "Teleportation-based QDS Simulation",

        "protocol_version":
            "1.0",

        "message":
            message,

        "message_hash":
            message_hash,

        "quantum_state":
            state,

        "measurement_basis":
            state,

        "expected_outcome":
            "0",

        "measurement_results":
            counts,

        "shots":
            shots
    }

    return signature


# ============================================================
# TEST
# ============================================================

if __name__ == "__main__":

    message = "SIH26141"

    signature = generate_signature(
        message
    )

    print()
    print("========================================")
    print("      QDS SIGNATURE GENERATION")
    print("========================================")

    print("\nSignature ID:")
    print(signature["signature_id"])

    print("\nTimestamp:")
    print(signature["timestamp"])

    print("\nProtocol:")
    print(signature["protocol"])

    print("\nProtocol Version:")
    print(signature["protocol_version"])

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

    print("\n========================================")