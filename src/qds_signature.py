import hashlib
from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def message_to_bit(message):
    """
    Convert a message into a deterministic quantum state bit
    using SHA-256.
    """
    digest = hashlib.sha256(message.encode()).hexdigest()

    # Use the first hexadecimal character
    # to derive a single bit.
    value = int(digest[0], 16)
    return value % 2


def generate_signature(message):
    """
    Prototype quantum signature generation.

    The message determines the quantum state.
    The state is then transferred using
    Bell-state-based quantum teleportation.
    """

    state_bit = message_to_bit(message)

    # 3 qubits:
    # q0 -> message/signing state
    # q1, q2 -> Bell pair
    qc = QuantumCircuit(3, 3)

    # ------------------------------------------------
    # 1. Prepare quantum state representing signature
    # ------------------------------------------------

    if state_bit == 1:
        qc.x(0)

    # ------------------------------------------------
    # 2. Create Bell state
    # ------------------------------------------------

    qc.h(1)
    qc.cx(1, 2)

    # ------------------------------------------------
    # 3. Alice performs teleportation operations
    # ------------------------------------------------

    qc.cx(0, 1)
    qc.h(0)

    # ------------------------------------------------
    # 4. Measure Alice's qubits
    # ------------------------------------------------

    qc.measure(0, 0)
    qc.measure(1, 1)

    # ------------------------------------------------
    # 5. Pauli corrections at Bob
    # ------------------------------------------------

    with qc.if_test((qc.clbits[1], 1)):
        qc.x(2)

    with qc.if_test((qc.clbits[0], 1)):
        qc.z(2)

    # ------------------------------------------------
    # 6. Projective measurement of Bob's qubit
    # ------------------------------------------------

    qc.measure(2, 2)

    # ------------------------------------------------
    # 7. Run simulation
    # ------------------------------------------------

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=1000
    ).result()

    counts = result.get_counts()

    return {
        "message": message,
        "message_hash": hashlib.sha256(
            message.encode()
        ).hexdigest(),
        "quantum_state": f"|{state_bit}>",
        "measurement_results": counts
    }


# ----------------------------------------------------
# Test signature generation
# ----------------------------------------------------

message = "SIH26141"

signature = generate_signature(message)

print("===== QDS SIGNATURE GENERATION =====")

print("\nMessage:")
print(signature["message"])

print("\nMessage Hash:")
print(signature["message_hash"])

print("\nQuantum Signature State:")
print(signature["quantum_state"])

print("\nMeasurement Results:")
print(signature["measurement_results"])