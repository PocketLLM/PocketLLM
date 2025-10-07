"""Tests for provider configuration service helpers."""

from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Any
from unittest.mock import Mock
from uuid import UUID, uuid4

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


class _StatusDatabase:
    """Async stub returning predefined provider records."""

    def __init__(self, records: list[dict[str, Any]]):
        self._records = list(records)

    async def select(self, *_args: Any, **_kwargs: Any) -> list[dict[str, Any]]:
        return list(self._records)


def _make_provider_record(
    user_id: UUID,
    *,
    provider: str,
    is_active: bool = True,
    has_api_key: bool = True,
    display_name: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    return {
        "id": uuid4(),
        "user_id": user_id,
        "provider": provider,
        "display_name": display_name,
        "base_url": None,
        "metadata": metadata or {},
        "api_key_hash": "hash" if has_api_key else None,
        "api_key_preview": "sk-****abcd" if has_api_key else None,
        "api_key_encrypted": None,
        "is_active": is_active,
        "created_at": now,
        "updated_at": now,
    }


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


@pytest.mark.asyncio
async def test_list_provider_statuses_includes_supported_providers() -> None:
    user_id = uuid4()
    database = _StatusDatabase([])
    settings = SimpleNamespace(encryption_key="test-key")
    service = ProvidersService(settings, database, catalogue=Mock())

    statuses = await service.list_provider_statuses(user_id)

    assert len(statuses) == 4
    assert [status.provider for status in statuses] == [
        "openai",
        "groq",
        "openrouter",
        "imagerouter",
    ]
    for status in statuses:
        assert status.configured is False
        assert status.is_active is False
        assert status.has_api_key is False
        assert status.message == "Provider is not configured yet."


@pytest.mark.asyncio
async def test_list_provider_statuses_uses_database_records() -> None:
    user_id = uuid4()
    record = _make_provider_record(
        user_id,
        provider="openai",
        display_name="Primary OpenAI",
        is_active=True,
        has_api_key=True,
    )
    database = _StatusDatabase([record])
    settings = SimpleNamespace(encryption_key="test-key")
    service = ProvidersService(settings, database, catalogue=Mock())

    statuses = await service.list_provider_statuses(user_id)
    openai_status = next(status for status in statuses if status.provider == "openai")

    assert openai_status.display_name == "Primary OpenAI"
    assert openai_status.configured is True
    assert openai_status.is_active is True
    assert openai_status.has_api_key is True
    assert openai_status.api_key_preview == "sk-****abcd"
    assert openai_status.message == "Provider is active and ready to use."


@pytest.mark.asyncio
async def test_list_provider_statuses_reports_missing_api_keys() -> None:
    user_id = uuid4()
    record = _make_provider_record(
        user_id,
        provider="groq",
        is_active=True,
        has_api_key=False,
    )
    database = _StatusDatabase([record])
    settings = SimpleNamespace(encryption_key="test-key")
    service = ProvidersService(settings, database, catalogue=Mock())

    statuses = await service.list_provider_statuses(user_id)
    groq_status = next(status for status in statuses if status.provider == "groq")

    assert groq_status.configured is True
    assert groq_status.has_api_key is False
    assert groq_status.message == "Provider is configured but missing an API key."


@pytest.mark.asyncio
async def test_list_provider_statuses_includes_additional_providers() -> None:
    user_id = uuid4()
    record = _make_provider_record(
        user_id,
        provider="anthropic",
        display_name="Anthropic",
        is_active=True,
        has_api_key=True,
    )
    database = _StatusDatabase([record])
    settings = SimpleNamespace(encryption_key="test-key")
    service = ProvidersService(settings, database, catalogue=Mock())

    statuses = await service.list_provider_statuses(user_id)

    providers = [status.provider for status in statuses]
    assert providers[:4] == ["openai", "groq", "openrouter", "imagerouter"]
    assert providers[-1] == "anthropic"

    anthropic_status = statuses[-1]
    assert anthropic_status.display_name == "Anthropic"
    assert anthropic_status.message == "Provider is active and ready to use."
