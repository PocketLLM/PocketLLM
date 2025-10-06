"""Utilities for encrypting and decrypting sensitive secrets."""

from __future__ import annotations

import binascii
import logging
from base64 import urlsafe_b64encode
from typing import TYPE_CHECKING

from cryptography.fernet import Fernet, InvalidToken

if TYPE_CHECKING:  # pragma: no cover - typing helper
    from app.core.config import Settings

logger = logging.getLogger(__name__)


def _derive_fernet_token(secret: str) -> bytes:
    """Derive a valid Fernet token from an arbitrary secret string."""

    digest = hashlib.sha256(secret.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest)


def _load_fernet(settings: "Settings") -> Fernet:
    """Return a :class:`Fernet` instance using the configured key."""

    key = getattr(settings, "encryption_key", None)
    if not key:
        raise RuntimeError(
            "Application encryption key is not configured. Set ENCRYPTION_KEY to a valid Fernet key."
        )
    token = key.encode("utf-8")
    try:
        return Fernet(token)
    except (ValueError, TypeError, binascii.Error) as exc:
        if len(token) == 32:
            derived_key = urlsafe_b64encode(token)
            logger.warning(
                "Provided ENCRYPTION_KEY was not base64 encoded; derived Fernet key from raw 32-byte string."
            )
            return Fernet(derived_key)
        raise RuntimeError(
            "Invalid encryption key format. Ensure ENCRYPTION_KEY is a base64 encoded Fernet key or a 32-character string."
        ) from exc
    except Exception as exc:  # pragma: no cover - defensive guard for invalid keys
        raise RuntimeError(
            "Invalid encryption key format. Ensure ENCRYPTION_KEY is a base64 encoded Fernet key or a 32-character string."
        ) from exc


def encrypt_secret(secret: str, settings: "Settings") -> str:
    """Encrypt ``secret`` using the configured Fernet key."""

    fernet = _load_fernet(settings)
    encrypted = fernet.encrypt(secret.encode("utf-8"))
    return encrypted.decode("utf-8")


def decrypt_secret(token: str, settings: "Settings") -> str:
    """Decrypt ``token`` returning the original secret string."""

    fernet = _load_fernet(settings)
    try:
        decrypted = fernet.decrypt(token.encode("utf-8"))
        return decrypted.decode("utf-8")
    except InvalidToken as exc:
        logger.error("Failed to decrypt stored secret: invalid token")
        raise RuntimeError("Stored secret could not be decrypted with the configured key") from exc


__all__ = ["encrypt_secret", "decrypt_secret"]

