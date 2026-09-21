class QDSServiceError(Exception):
    """Base exception for QDS service operations."""
    pass


class KeyManagementError(QDSServiceError):
    """Raised when key generation, lookup, or registration fails."""
    pass


class PacketValidationError(QDSServiceError):
    """Raised when an incoming packet structure is invalid or malformed."""
    pass


class CryptoError(QDSServiceError):
    """Raised when a cryptographic signature generation or verification operation fails unexpectedly."""
    pass
