"""Utility helpers for preparing data payloads for Supabase."""

from __future__ import annotations

from datetime import date, datetime
from typing import Any

JsonLike = Any


def _serialise_value(value: Any) -> Any:
    """Recursively serialise date and datetime values to ISO strings."""

    if isinstance(value, datetime):
        return value.isoformat()
    if isinstance(value, date):
        return value.isoformat()
    if isinstance(value, dict):
        return {key: _serialise_value(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_serialise_value(item) for item in value]
    if isinstance(value, tuple):
        return tuple(_serialise_value(item) for item in value)
    return value


def serialize_dates_for_json(data: JsonLike) -> JsonLike:
    """Convert ``date`` and ``datetime`` instances into ISO 8601 strings.

    Supabase's REST interface requires JSON-serialisable payloads. Python's
    ``date`` and ``datetime`` objects are not JSON serialisable by default,
    so this helper walks nested structures and replaces them with ISO 8601
    strings while leaving other values untouched.
    """

    return _serialise_value(data)


__all__ = ["serialize_dates_for_json"]
