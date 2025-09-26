"""Utility helpers for the PocketLLM backend."""

from importlib import import_module
from typing import Any

__all__ = [
    "create_supabase_service_headers",
    "decode_access_token",
    "hash_secret",
    "mask_secret",
    "verify_secret",
]


def __getattr__(name: str) -> Any:
    if name in __all__:
        module = import_module("app.utils.security")
        return getattr(module, name)
    raise AttributeError(f"module {__name__} has no attribute {name}")
