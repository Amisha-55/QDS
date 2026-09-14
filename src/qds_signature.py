import hashlib
import secrets
from datetime import datetime
import uuid

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator




PAULI_BASES = ["Z", "X", "Y"]

PROTOCOL_NAME = (
    "Teleportation-based Quantum Signature Simulation"
)

PROTOCOL_VERSION = "2.0"



def calculate_message_hash(message):
    """
    Calculate the classical SHA-256 fingerprint of the message.

    IMPORTANT:
        This hash is used ONLY as a classical integrity component.

        It is NOT used to select the quantum states.
        It is NOT used to generate the quantum signature.
    """

    if not isinstance(message, str):
        raise TypeError("Message must be a string")

    if not message:
        raise ValueError("Message cannot be empty")

    return hashlib.sha256(
        message.encode("utf-8")
    ).hexdigest()




def message_to_bits(message):
    """
    Convert the UTF-8 encoded message into a sequence of bits.

    Example:

        "A"
          ↓
        01000001
    """

    if not isinstance(message, str):
        raise TypeError("Message must be a string")

    if not message:
        raise ValueError("Message cannot be empty")

    data = message.encode("utf-8")

    bits = []

    for byte in data:
        for shift in range(7, -1, -1):
            bits.append(
                (byte >> shift) & 1
            )

    return bits




def prepare_state(
    qc,
    basis,
    bit,
    qubit=0
):
    """
    Prepare one of six Pauli eigenstates.

    basis = Z:
        bit 0 -> |0>
        bit 1 -> |1>

    basis = X:
        bit 0 -> |+>
        bit 1 -> |->

    basis = Y:
        bit 0 -> |+i>
        bit 1 -> |-i>

    The state is chosen independently of SHA-256.
    """

    if basis not in PAULI_BASES:
        raise ValueError(
            "Basis must be Z, X, or Y"
        )

    if bit not in (0, 1):
        raise ValueError(
            "Bit must be 0 or 1"
        )


    if basis == "Z":

        if bit == 1:
            qc.x(qubit)

  

    elif basis == "X":

        qc.h(qubit)

        if bit == 1:
            qc.z(qubit)

    

    elif basis == "Y":

        # |+i> = S H |0>
        qc.h(qubit)
        qc.s(qubit)

        # |-i> = Z |+i>
        if bit == 1:
            qc.z(qubit)



def apply_measurement_basis(
    qc,
    basis,
    qubit
):
    """
    Rotate the selected Pauli basis into the computational
    Z basis before measurement.
    """

    if basis == "Z":

        # Already in Z basis.
        pass

    elif basis == "X":

        # X basis -> Z basis
        qc.h(qubit)

    elif basis == "Y":

        # Y basis -> Z basis
        qc.sdg(qubit)
        qc.h(qubit)

    else:

        raise ValueError(
            "Basis must be Z, X, or Y"
        )



def create_bell_pair(qc):
    """
    Create:

        |Phi+> = (|00> + |11>) / sqrt(2)

    using q1 and q2.
    """

    qc.h(1)
    qc.cx(1, 2)




def teleport_state(
    qc,
    basis,
    bit
):
    """
    Teleport the quantum state encoded by (basis, bit)
    from q0 to q2.

    Qubits:

        q0 -> message state
        q1 -> Alice's Bell qubit
        q2 -> Bob's Bell qubit

    Classical bits:

        c0 -> Alice's first measurement
        c1 -> Alice's second measurement
        c2 -> Bob's final measurement
    """

    # --------------------------------------------------------
    # 1. Prepare message state
    # --------------------------------------------------------

    prepare_state(
        qc,
        basis,
        bit,
        qubit=0
    )

    

    create_bell_pair(qc)


    qc.cx(0, 1)
    qc.h(0)

    qc.measure(0, 0)
    qc.measure(1, 1)

 
    # X correction controlled by c1
    with qc.if_test(
        (qc.clbits[1], 1)
    ):
        qc.x(2)

    # Z correction controlled by c0
    with qc.if_test(
        (qc.clbits[0], 1)
    ):
        qc.z(2)

   

    apply_measurement_basis(
        qc,
        basis,
        qubit=2
    )

    qc.measure(2, 2)



def generate_quantum_signature_element(
    bit,
    shots
):
    """
    Generate and simulate one quantum signature element.

    A random Pauli basis is selected independently from the
    classical SHA-256 fingerprint.

    The message bit determines whether the + or - eigenstate
    is prepared.

    Returns the basis, bit, measurement results and accuracy.
    """

    basis = secrets.choice(
        PAULI_BASES
    )

    qc = QuantumCircuit(3, 3)

    teleport_state(
        qc,
        basis,
        bit
    )

    simulator = AerSimulator()

    result = simulator.run(
        qc,
        shots=shots
    ).result()

    counts = result.get_counts()

    

    expected_bit = bit

    correct_shots = 0

    for outcome, count in counts.items():

        if not outcome:
            continue

        # Qiskit displays c2 c1 c0.
        bob_bit = int(
            outcome[0]
        )

        if bob_bit == expected_bit:
            correct_shots += count

    accuracy = (
        correct_shots / shots
    )

    return {
        "basis": basis,
        "bit": bit,
        "expected_outcome": str(bit),
        "measurement_results": counts,
        "correct_shots": correct_shots,
        "shots": shots,
        "accuracy": accuracy
    }



def generate_signature(
    message,
    shots=1000,
    max_bits=None
):
    """
    Generate a teleportation-based quantum signature
    simulation.

    Architecture:

        MESSAGE
           |
           +--------------------------+
           |                          |
           v                          v
      SHA-256                    UTF-8 bits
           |                          |
           v                          v
    classical fingerprint      quantum encoding
                                      |
                                      v
                                random Pauli basis
                                      |
                                      v
                                teleportation
                                      |
                                      v
                                measurement
                                      |
                                      v
                              quantum signature

    SHA-256 is NOT used to select the quantum states.

    This is a QDS-inspired simulation/prototype, not a
    production quantum digital signature implementation.
    """

   

    if not isinstance(message, str):
        raise TypeError(
            "Message must be a string"
        )

    if not message:
        raise ValueError(
            "Message cannot be empty"
        )

    if not isinstance(shots, int):
        raise TypeError(
            "Shots must be an integer"
        )

    if shots <= 0:
        raise ValueError(
            "Shots must be greater than zero"
        )

    
    message_hash = calculate_message_hash(
        message
    )


    message_bits = message_to_bits(
        message
    )

    # Prevent extremely large circuits during experimentation.
    if max_bits is not None:

        if not isinstance(max_bits, int):
            raise TypeError(
                "max_bits must be an integer or None"
            )

        if max_bits <= 0:
            raise ValueError(
                "max_bits must be greater than zero"
            )

        message_bits = message_bits[
            :max_bits
        ]

    quantum_signature = []

    for index, bit in enumerate(
        message_bits
    ):

        element = (
            generate_quantum_signature_element(
                bit=bit,
                shots=shots
            )
        )

        element["index"] = index

        quantum_signature.append(
            element
        )

   

    total_correct = sum(
        element["correct_shots"]
        for element in quantum_signature
    )

    total_shots = sum(
        element["shots"]
        for element in quantum_signature
    )

    quantum_accuracy = (
        total_correct / total_shots
        if total_shots > 0
        else 0.0
    )

   

    signature = {

        "signature_id":
            str(uuid.uuid4()),

        "timestamp":
            datetime.now().isoformat(),

        "protocol":
            PROTOCOL_NAME,

        "protocol_version":
            PROTOCOL_VERSION,

     

        "classical_integrity": {

            "hash_algorithm":
                "SHA-256",

            "message_hash":
                message_hash
        },

       

        "message_length_bytes":
            len(
                message.encode("utf-8")
            ),

        "quantum_bit_count":
            len(message_bits),

       

        "quantum_signature": {

            "encoding":
                "Pauli eigenstates",

            "bases":
                PAULI_BASES,

            "transport":
                "Quantum teleportation",

            "elements":
                quantum_signature,

            "overall_accuracy":
                quantum_accuracy
        },

      

        "shots":
            shots
    }

    return signature




if __name__ == "__main__":

    message = "SIH26141"

    signature = generate_signature(
        message,
        shots=1000
    )

    print()
    print("=" * 60)
    print("     TELEPORTATION-BASED QUANTUM SIGNATURE")
    print("=" * 60)

    print("\nSignature ID:")
    print(signature["signature_id"])

    print("\nProtocol:")
    print(signature["protocol"])

    print("\nProtocol Version:")
    print(signature["protocol_version"])

    print("\nMessage:")
    print(message)

    print("\nClassical Integrity:")
    print(
        signature[
            "classical_integrity"
        ]
    )

    print("\nQuantum Bit Count:")
    print(
        signature[
            "quantum_bit_count"
        ]
    )

    print("\nQuantum Encoding:")
    print(
        signature[
            "quantum_signature"
        ][
            "encoding"
        ]
    )

    print("\nQuantum Transport:")
    print(
        signature[
            "quantum_signature"
        ][
            "transport"
        ]
    )

    print("\nQuantum Verification Accuracy:")
    print(
        f"{signature['quantum_signature']['overall_accuracy'] * 100:.2f}%"
    )

    print("\nNumber of Quantum Signature Elements:")
    print(
        len(
            signature[
                "quantum_signature"
            ][
                "elements"
            ]
        )
    )

    print("\n" + "=" * 60)