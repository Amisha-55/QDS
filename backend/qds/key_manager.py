import os
import sys
from typing import Tuple, Optional, Dict, Any

# Ensure src/ is importable
SRC_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "src"))
if SRC_DIR not in sys.path:
    sys.path.insert(0, SRC_DIR)

from classical_signature import generate_key_pair
from trusted_keys import register_public_key, get_public_key, user_exists, load_registry, save_registry
from cryptography.hazmat.primitives import serialization
from backend.qds.exceptions import KeyManagementError


class KeyManager:
    """
    Manages session private keys and bridges to the persistent trusted public key registry.
    """

    def __init__(self, allow_key_rotation: bool = True):
        self.allow_key_rotation = allow_key_rotation
        # In-memory session store for private keys: user_id -> private_key
        self._private_keys: Dict[str, Any] = {}
        # In-memory session store for public keys: user_id -> public_key
        self._public_keys: Dict[str, Any] = {}

    def get_or_create_key_pair(self, user_id: str) -> Tuple[Any, Any]:
        """
        Retrieve existing session key pair for user_id, or generate a fresh one
        and register its public key with the trusted registry.
        """
        if not isinstance(user_id, str) or not user_id.strip():
            raise KeyManagementError("User ID must be a non-empty string.")

        user_id = user_id.strip()

        if user_id in self._private_keys and user_id in self._public_keys:
            return self._private_keys[user_id], self._public_keys[user_id]

        # Generate fresh key pair
        private_key, public_key = generate_key_pair()
        self._private_keys[user_id] = private_key
        self._public_keys[user_id] = public_key

        # Try to register public key in trusted registry
        try:
            register_public_key(user_id, public_key)
        except ValueError:
            if self.allow_key_rotation:
                # Update the persistent registry with the new valid public key
                self.force_register_public_key(user_id, public_key)
            else:
                # Fall back to existing key if rotation not allowed
                pub = get_public_key(user_id)
                self._public_keys[user_id] = pub

        return self._private_keys[user_id], self._public_keys[user_id]

    def force_register_public_key(self, user_id: str, public_key: Any) -> None:
        """Register or overwrite public key in the trusted registry."""
        registry = load_registry()
        public_key_pem = public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo,
        ).decode("utf-8")
        registry[user_id] = public_key_pem
        save_registry(registry)
        self._public_keys[user_id] = public_key

    def register_key_pair(self, user_id: str, private_key: Any, public_key: Any) -> None:
        """Register an existing key pair into session and trusted registry."""
        if not user_id or not isinstance(user_id, str):
            raise KeyManagementError("User ID must be a non-empty string.")

        user_id = user_id.strip()
        self._private_keys[user_id] = private_key
        self._public_keys[user_id] = public_key

        try:
            register_public_key(user_id, public_key)
        except ValueError:
            # Already registered with same or different key
            pass

    def get_private_key(self, user_id: str) -> Optional[Any]:
        """Retrieve active session private key for user_id, if available."""
        return self._private_keys.get(user_id)

    def get_trusted_public_key(self, user_id: str) -> Optional[Any]:
        """
        Retrieve trusted public key for user_id.
        Checks in-memory cache first, then falls back to persistent trusted registry.
        """
        if not user_id or not isinstance(user_id, str):
            return None

        user_id = user_id.strip()

        if user_id in self._public_keys:
            return self._public_keys[user_id]

        if user_exists(user_id):
            try:
                pub = get_public_key(user_id)
                self._public_keys[user_id] = pub
                return pub
            except Exception as err:
                raise KeyManagementError(f"Failed to load trusted public key for {user_id}: {err}") from err

        return None

    def has_trusted_key(self, user_id: str) -> bool:
        """Check if user_id has a registered public key."""
        if not user_id or not isinstance(user_id, str):
            return False
        user_id = user_id.strip()
        return user_id in self._public_keys or user_exists(user_id)
