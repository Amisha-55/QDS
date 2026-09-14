import json
import os

from cryptography.hazmat.primitives import serialization


REGISTRY_FILE = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "keys",
    "public_keys.json"
)


def ensure_registry():
    registry_folder = os.path.dirname(REGISTRY_FILE)

    os.makedirs(
        registry_folder,
        exist_ok=True
    )

    if not os.path.exists(REGISTRY_FILE):
        with open(REGISTRY_FILE, "w") as file:
            json.dump({}, file, indent=4)


def load_registry():
    ensure_registry()

    with open(REGISTRY_FILE, "r") as file:
        return json.load(file)


def save_registry(registry):
    ensure_registry()

    with open(REGISTRY_FILE, "w") as file:
        json.dump(
            registry,
            file,
            indent=4
        )


def register_public_key(
    user_id,
    public_key
):
    registry = load_registry()

    public_key_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode("utf-8")

    registry[user_id] = public_key_pem

    save_registry(registry)

    print(
        f"Public key registered successfully for {user_id}"
    )


def get_public_key(user_id):
    registry = load_registry()

    if user_id not in registry:
        raise ValueError(
            f"No trusted public key found for {user_id}"
        )

    public_key_pem = registry[user_id].encode("utf-8")

    public_key = serialization.load_pem_public_key(
        public_key_pem
    )

    return public_key


def user_exists(user_id):
    registry = load_registry()

    return user_id in registry


if __name__ == "__main__":

    print("===== TRUSTED KEY REGISTRY =====")

    registry = load_registry()

    if not registry:
        print("No public keys registered yet.")

    else:
        print("Registered users:")

        for user_id in registry:
            print(f"- {user_id}")