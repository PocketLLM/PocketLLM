"""Tests for encryption utilities handling Fernet keys."""

from __future__ import annotations

from types import SimpleNamespace

import pytest
from cryptography.fernet import Fernet

from app.utils.crypto import decrypt_secret, encrypt_secret


@pytest.mark.parametrize(
    "encryption_key",
    [
        Fernet.generate_key().decode("utf-8"),
        "plain-text-secret",
    ],
)
def test_encrypt_decrypt_roundtrip(encryption_key: str) -> None:
    settings = SimpleNamespace(encryption_key=encryption_key)
    secret = "super-secret-value"

    token = encrypt_secret(secret, settings)

    assert decrypt_secret(token, settings) == secret


def test_missing_encryption_key_raises_runtime_error() -> None:
    settings = SimpleNamespace(encryption_key="")

    with pytest.raises(RuntimeError):
        encrypt_secret("value", settings)
