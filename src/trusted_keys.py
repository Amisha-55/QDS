import json
import os

from cryptography.hazmat.primitives import serialization


REGISTRY_FILE = os.path.join(
    os.path.dirname(os.path.dirname(__file__)),
    "keys",
    "public_keys.json"
)


def ensure_registry():
    """
    Make sure the trusted-key registry and its directory exist.
    """

    registry_folder = os.path.dirname(
        REGISTRY_FILE
    )

    os.makedirs(
        registry_folder,
        exist_ok=True
    )

    if not os.path.exists(REGISTRY_FILE):

        with open(
            REGISTRY_FILE,
            "w",
            encoding="utf-8"
        ) as file:

            json.dump(
                {},
                file,
                indent=4
            )


def load_registry():
    """
    Load the trusted public-key registry.
    """

    ensure_registry()

    try:

        with open(
            REGISTRY_FILE,
            "r",
            encoding="utf-8"
        ) as file:

            registry = json.load(file)

    except json.JSONDecodeError as error:

        raise ValueError(
            "Trusted key registry is corrupted."
        ) from error

    if not isinstance(registry, dict):

        raise ValueError(
            "Trusted key registry must contain a JSON object."
        )

    return registry


def save_registry(registry):
    """
    Save the trusted public-key registry.
    """

    if not isinstance(registry, dict):
        raise TypeError(
            "Registry must be a dictionary"
        )

    ensure_registry()

    with open(
        REGISTRY_FILE,
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            registry,
            file,
            indent=4
        )


def register_public_key(
    user_id,
    public_key
):
    """
    Register an Ed25519 public key for a user.

    In this prototype, the registry itself is treated
    as trusted configuration.
    """

    if not isinstance(user_id, str):
        raise TypeError(
            "User ID must be a string"
        )

    if not user_id.strip():
        raise ValueError(
            "User ID cannot be empty"
        )

    registry = load_registry()


    public_key_pem = public_key.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    ).decode("utf-8")

    if user_id in registry:

        if registry[user_id] != public_key_pem:

            raise ValueError(
                f"A different public key is already "
                f"registered for {user_id}"
            )

        return



    registry[user_id] = public_key_pem

    save_registry(
        registry
    )

    print(
        f"Public key registered successfully for {user_id}"
    )


def get_public_key(user_id):
    """
    Retrieve the trusted public key for a user.
    """

    if not isinstance(user_id, str):
        raise TypeError(
            "User ID must be a string"
        )

    registry = load_registry()

    if user_id not in registry:

        raise ValueError(
            f"No trusted public key found for {user_id}"
        )

    public_key_pem = registry[user_id].encode(
        "utf-8"
    )

    try:

        public_key = serialization.load_pem_public_key(
            public_key_pem
        )

    except ValueError as error:

        raise ValueError(
            f"Stored public key for {user_id} is invalid."
        ) from error

    return public_key


def user_exists(user_id):
    """
    Check whether a user has a registered
    trusted public key.
    """

    if not isinstance(user_id, str):
        return False

    registry = load_registry()

    return user_id in registry


if __name__ == "__main__":

    print(
        "===== TRUSTED KEY REGISTRY ====="
    )

    registry = load_registry()

    if not registry:

        print(
            "No public keys registered yet."
        )

    else:

        print(
            "Registered users:"
        )

        for user_id in registry:

            print(
                f"- {user_id}"
            )