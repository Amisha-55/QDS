from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey
)

from cryptography.hazmat.primitives import serialization


def generate_key_pair():
    """
    Generate a new Ed25519 private/public key pair.
    """

    private_key = Ed25519PrivateKey.generate()
    public_key = private_key.public_key()

    return private_key, public_key


def save_private_key(private_key, filename):
    """
    Save an Ed25519 private key in PEM format.

    WARNING:
    The private key should be stored securely.
    """

    with open(
        filename,
        "wb"
    ) as file:

        file.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
        )


def save_public_key(public_key, filename):
    """
    Save an Ed25519 public key in PEM format.
    """

    with open(
        filename,
        "wb"
    ) as file:

        file.write(
            public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )
        )


def load_private_key(filename):
    """
    Load an Ed25519 private key from PEM format.
    """

    with open(
        filename,
        "rb"
    ) as file:

        private_key = serialization.load_pem_private_key(
            file.read(),
            password=None
        )

    if not isinstance(
        private_key,
        Ed25519PrivateKey
    ):
        raise TypeError(
            "Loaded key is not an Ed25519 private key"
        )

    return private_key


def load_public_key(filename):
    """
    Load an Ed25519 public key from PEM format.
    """

    with open(
        filename,
        "rb"
    ) as file:

        public_key = serialization.load_pem_public_key(
            file.read()
        )

    if not isinstance(
        public_key,
        Ed25519PublicKey
    ):
        raise TypeError(
            "Loaded key is not an Ed25519 public key"
        )

    return public_key


def sign_data(private_key, data):
    """
    Sign data using an Ed25519 private key.

    Returns:
        bytes: Ed25519 digital signature
    """

    if isinstance(data, str):
        data = data.encode("utf-8")

    if not isinstance(data, bytes):
        raise TypeError(
            "Data must be a string or bytes"
        )

    return private_key.sign(data)


def verify_data(
    public_key,
    data,
    signature
):
    """
    Verify an Ed25519 digital signature.

    Returns:
        True  -> signature is valid
        False -> signature is invalid
    """

    if isinstance(data, str):
        data = data.encode("utf-8")

    if not isinstance(data, bytes):
        raise TypeError(
            "Data must be a string or bytes"
        )

    if not isinstance(signature, bytes):
        raise TypeError(
            "Signature must be bytes"
        )

    try:

        public_key.verify(
            signature,
            data
        )

        return True

    except Exception:

        return False



if __name__ == "__main__":

    print(
        "========================================"
    )

    print(
        "     CLASSICAL DIGITAL SIGNATURE TEST"
    )

    print(
        "========================================"
    )

   

    private_key, public_key = generate_key_pair()

    

    message = "Hello Rudra"

    signature = sign_data(
        private_key,
        message
    )

    

    valid = verify_data(
        public_key,
        message,
        signature
    )

    print("\nMessage:")
    print(message)

    print("\nSignature generated:")
    print(signature.hex())

    print("\nVerification:")
    print(valid)

    

    tampered_message = "Hello Attacker"

    tampered_valid = verify_data(
        public_key,
        tampered_message,
        signature
    )

    print("\nTampered Message:")
    print(tampered_message)

    print("\nTampered Verification:")
    print(tampered_valid)

    print(
        "\n========================================"
    )