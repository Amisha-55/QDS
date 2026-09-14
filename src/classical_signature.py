from cryptography.hazmat.primitives.asymmetric.ed25519 import (
    Ed25519PrivateKey,
    Ed25519PublicKey
)

from cryptography.hazmat.primitives import serialization


def generate_key_pair():
    private_key = Ed25519PrivateKey.generate()
    public_key = private_key.public_key()

    return private_key, public_key


def save_private_key(private_key, filename):
    with open(filename, "wb") as file:
        file.write(
            private_key.private_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PrivateFormat.PKCS8,
                encryption_algorithm=serialization.NoEncryption()
            )
        )


def save_public_key(public_key, filename):
    with open(filename, "wb") as file:
        file.write(
            public_key.public_bytes(
                encoding=serialization.Encoding.PEM,
                format=serialization.PublicFormat.SubjectPublicKeyInfo
            )
        )


def load_private_key(filename):
    with open(filename, "rb") as file:
        return serialization.load_pem_private_key(
            file.read(),
            password=None
        )


def load_public_key(filename):
    with open(filename, "rb") as file:
        return serialization.load_pem_public_key(
            file.read()
        )


def sign_data(private_key, data):
    if isinstance(data, str):
        data = data.encode("utf-8")

    return private_key.sign(data)


def verify_data(public_key, data, signature):
    if isinstance(data, str):
        data = data.encode("utf-8")

    try:
        public_key.verify(signature, data)
        return True

    except Exception:
        return False


if __name__ == "__main__":
    print("===== CLASSICAL DIGITAL SIGNATURE TEST =====")

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