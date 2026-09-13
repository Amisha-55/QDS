import base64
import json

from qds_signature import generate_signature
from qds_verify import verify_signature

from classical_signature import sign_data
from classical_signature import verify_data


def canonical_json(data):
    return json.dumps(
        data,
        sort_keys=True,
        separators=(",", ":")
    ).encode("utf-8")


def create_secure_packet(
    message,
    private_key,
    signer_id
):
    qds_signature = generate_signature(message)

    payload = {
        "signer_id": signer_id,
        "message": message,
        "qds_signature": qds_signature
    }

    payload_bytes = canonical_json(payload)

    classical_signature = sign_data(
        private_key,
        payload_bytes
    )

    packet = {
        "payload": payload,
        "classical_signature": base64.b64encode(
            classical_signature
        ).decode("ascii")
    }

    return packet


def verify_secure_packet(
    packet,
    public_key
):
    payload = packet["payload"]

    classical_signature = base64.b64decode(
        packet["classical_signature"]
    )

    payload_bytes = canonical_json(payload)

    classical_valid = verify_data(
        public_key,
        payload_bytes,
        classical_signature
    )

    if classical_valid:
        qds_result = verify_signature(
            payload["qds_signature"],
            payload["message"]
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
        "classical_signature_valid": classical_valid,
        "qds_result": qds_result,
        "final_decision": final_decision
    }