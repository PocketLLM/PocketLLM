"""Utility helpers for the PocketLLM backend."""

from importlib import import_module
from typing import Any

_SECURITY_EXPORTS = {
    "create_supabase_service_headers",
    "decode_access_token",
    "hash_secret",
    "mask_secret",
    "verify_secret",
}

_CRYPTO_EXPORTS = {
    "encrypt_secret",
    "decrypt_secret",
}

__all__ = sorted(_SECURITY_EXPORTS | _CRYPTO_EXPORTS)


def __getattr__(name: str) -> Any:
    if name in _SECURITY_EXPORTS:
        module = import_module("app.utils.security")
        return getattr(module, name)
    if name in _CRYPTO_EXPORTS:
        module = import_module("app.utils.crypto")
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
