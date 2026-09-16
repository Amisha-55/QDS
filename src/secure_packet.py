import base64
import json

from qds_signature import generate_signature
from qds_verify import verify_signature

from classical_signature import sign_data
from classical_signature import verify_data


def canonical_json(data):
    """
    Convert data into a deterministic JSON representation.

    The same data will always produce the same byte sequence,
    which is important because Ed25519 signs bytes.
    """

    return json.dumps(
        data,
        sort_keys=True,
        separators=(",", ":")
    ).encode("utf-8")


def create_secure_packet(
    message,
    private_key,
    signer_id,
    max_bits=None  # Step 1: Remove the hardcoded 8
):
    
    # ... (keep your existing error checks here) ...

    # Step 2: Dynamically calculate the exact number of bits required
    # 1 character = 1 byte = 8 bits
    if max_bits is None:
        max_bits = len(message) * 8 

  
    """
    Create a secure packet containing:

    1. Original message
    2. Quantum signature information
    3. Signer identity
    4. Ed25519 classical signature

    SHA-256 is contained inside the QDS signature only as
    a classical message fingerprint.

    Ed25519 provides classical authenticity and protects
    the complete payload, including the quantum signature.
    """


    if not isinstance(message, str):
        raise TypeError("Message must be a string")

    if not message:
        raise ValueError("Message cannot be empty")

    if not isinstance(signer_id, str):
        raise TypeError("Signer ID must be a string")

    if not signer_id:
        raise ValueError("Signer ID cannot be empty")

    

    qds_signature = generate_signature(
        message,
        max_bits=max_bits
    )

    

    payload = {
        "signer_id": signer_id,
        "message": message,
        "qds_signature": qds_signature
    }

    

    payload_bytes = canonical_json(
        payload
    )

   

    classical_signature = sign_data(
        private_key,
        payload_bytes
    )



    encoded_signature = base64.b64encode(
        classical_signature
    ).decode("ascii")

    

    packet = {
        "payload": payload,
        "classical_signature": encoded_signature
    }

    return packet


def verify_secure_packet(
    packet,
    public_key,
    threshold=0.95
):
    """
    Verify a complete secure packet.

    Verification happens in two layers:

        Layer 1:
        Ed25519 classical signature
        ↓
        Proves the payload was signed by the holder
        of the corresponding private key.

        Layer 2:
        QDS-inspired quantum verification
        ↓
        Checks the quantum signature information
        and measurement statistics.

    The packet is TRUSTED only when both layers pass.
    """

    

    if not isinstance(packet, dict):
        raise TypeError("Packet must be a dictionary")

    if "payload" not in packet:
        return {
            "classical_signature_valid": False,
            "qds_result": {
                "decision": "NOT VERIFIED"
            },
            "final_decision": "INVALID / SUSPICIOUS"
        }

    if "classical_signature" not in packet:
        return {
            "classical_signature_valid": False,
            "qds_result": {
                "decision": "NOT VERIFIED"
            },
            "final_decision": "INVALID / SUSPICIOUS"
        }

    payload = packet["payload"]

    if not isinstance(payload, dict):
        return {
            "classical_signature_valid": False,
            "qds_result": {
                "decision": "NOT VERIFIED"
            },
            "final_decision": "INVALID / SUSPICIOUS"
        }

    

    required_fields = {
        "signer_id",
        "message",
        "qds_signature"
    }

    if not required_fields.issubset(payload.keys()):
        return {
            "classical_signature_valid": False,
            "qds_result": {
                "decision": "NOT VERIFIED"
            },
            "final_decision": "INVALID / SUSPICIOUS"
        }

    

    try:
        classical_signature = base64.b64decode(
            packet["classical_signature"],
            validate=True
        )

    except Exception:

        return {
            "classical_signature_valid": False,
            "qds_result": {
                "decision": "NOT VERIFIED"
            },
            "final_decision": "INVALID / SUSPICIOUS"
        }

    

    payload_bytes = canonical_json(
        payload
    )

    

    classical_valid = verify_data(
        public_key,
        payload_bytes,
        classical_signature
    )

    
    if classical_valid:

        qds_result = verify_signature(
            payload["qds_signature"],
            payload["message"],
            threshold=threshold
        )

    else:

        qds_result = {
            "decision": "NOT VERIFIED"
        }

    

    if (
        classical_valid
        and qds_result["decision"] == "VALID"
    ):
        final_decision = "TRUSTED"

    else:
        final_decision = "INVALID / SUSPICIOUS"

   

    return {
        "signer_id": payload.get(
            "signer_id"
        ),

        "classical_signature_valid": classical_valid,

        "qds_result": qds_result,

        "final_decision": final_decision
    }




if __name__ == "__main__":

    from classical_signature import (
        generate_key_pair
    )

    
    

    private_key, public_key = generate_key_pair()

    

    message = "SIH26141"

    packet = create_secure_packet(
        message,
        private_key,
        "Alice"
    )

  

    result = verify_secure_packet(
        packet,
        public_key
    )

    # -----------------------------------------------
    # Display results
    # -----------------------------------------------

    print(
        "========================================"
    )

    print(
        "        SECURE PACKET VERIFICATION"
    )

    print(
        "========================================"
    )

    print("\nSigner ID:")
    print(
        result["signer_id"]
    )

    print("\nMessage:")
    print(
        packet["payload"]["message"]
    )

    print("\nClassical Ed25519 Signature Valid:")
    print(
        result["classical_signature_valid"]
    )

    print("\nQDS Verification:")
    print(
        result["qds_result"]["decision"]
    )

    print("\nFinal Decision:")
    print(
        result["final_decision"]
    )

    print(
        "\n========================================"
    )