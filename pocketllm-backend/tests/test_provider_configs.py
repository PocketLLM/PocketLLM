"""Tests for provider configuration service helpers."""

from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Any
from unittest.mock import Mock
from uuid import uuid4

import pytest

pytest.importorskip("pydantic")

from app.schemas.providers import ProviderUpdateRequest
from app.services.provider_configs import ProvidersService


class _StubDatabase:
    """Minimal async database stub for provider update tests."""

    def __init__(self, record: dict[str, Any]):
        self._record = record
        self.last_update: dict[str, Any] | None = None
        self.last_filters: dict[str, Any] | None = None

    async def select(self, *_args: Any, **_kwargs: Any) -> list[dict[str, Any]]:
        return [self._record]

    async def update(self, _table: str, data: dict[str, Any], *, filters: dict[str, Any]) -> list[dict[str, Any]]:
        self.last_update = data
        self.last_filters = filters
        merged = {**self._record, **data}
        merged.setdefault("metadata", {})
        merged["updated_at"] = datetime.now(timezone.utc)
        self._record = merged
        return [merged]


@pytest.mark.asyncio
async def test_update_provider_clears_api_key_when_null() -> None:
    user_id = uuid4()
    record = {
        "id": uuid4(),
        "user_id": user_id,
        "provider": "openai",
        "display_name": None,
        "base_url": None,
        "metadata": {},
        "api_key_hash": "hash-value",
        "api_key_preview": "sk-****abcd",
        "api_key_encrypted": "encrypted-value",
        "is_active": True,
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    }

    database = _StubDatabase(record)
    settings = SimpleNamespace(encryption_key="test-key")
    service = ProvidersService(settings, database, catalogue=Mock())

    payload = ProviderUpdateRequest(api_key=None)
    result = await service.update_provider(user_id, "openai", payload)

    assert database.last_update == {
        "api_key_hash": None,
        "api_key_preview": None,
        "api_key_encrypted": None,
    }
    assert database.last_filters == {"user_id": str(user_id), "provider": "openai"}
    assert result.provider == "openai"
    assert result.api_key_preview is None
    assert result.has_api_key is False

