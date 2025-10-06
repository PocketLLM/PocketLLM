"""Tests for crypto utility helpers."""

from __future__ import annotations

import pytest

from cryptography.fernet import Fernet

from app.utils.crypto import decrypt_secret, encrypt_secret


class _Settings:
    def __init__(self, encryption_key: str) -> None:
        self.encryption_key = encryption_key


@pytest.mark.parametrize("secret", ["hello", "123", "🚀"])
def test_encrypt_decrypt_roundtrip_with_base64_key(secret: str) -> None:
    key = Fernet.generate_key().decode("utf-8")
    settings = _Settings(encryption_key=key)

    token = encrypt_secret(secret, settings)

    assert decrypt_secret(token, settings) == secret


@pytest.mark.parametrize("secret", ["token", "another secret"])
def test_encrypt_decrypt_with_raw_32_char_key(secret: str) -> None:
    raw_key = "a" * 32
    settings = _Settings(encryption_key=raw_key)

    token = encrypt_secret(secret, settings)

    assert decrypt_secret(token, settings) == secret


def test_encrypt_with_invalid_key_raises() -> None:
    settings = _Settings(encryption_key="short")

    with pytest.raises(RuntimeError):
        encrypt_secret("secret", settings)
