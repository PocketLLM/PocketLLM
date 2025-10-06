"""Tests for provider configuration service helpers."""

from __future__ import annotations

import asyncio
from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Any
from unittest.mock import Mock
from uuid import UUID, uuid4

import pytest

pytest.importorskip("pydantic")

from cryptography.fernet import Fernet

from app.schemas.providers import ProviderActivationRequest, ProviderUpdateRequest
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


class _RecordingDatabase:
    def __init__(self) -> None:
        self.last_upsert: dict[str, Any] | None = None
        self.last_on_conflict: str | None = None

    async def upsert(self, _table: str, payload: dict[str, Any], *, on_conflict: str) -> list[dict[str, Any]]:
        self.last_upsert = dict(payload)
        self.last_on_conflict = on_conflict
        record = dict(payload)
        record.setdefault("metadata", {})
        record.update(
            {
                "id": uuid4(),
                "user_id": UUID(payload["user_id"]),
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc),
            }
        )
        return [record]

    async def select(self, *_args: Any, **_kwargs: Any) -> list[dict[str, Any]]:  # pragma: no cover - unused helper
        return []


class _RecordingValidator:
    def __init__(self) -> None:
        self.calls: list[dict[str, Any]] = []

    async def validate(
        self,
        provider: str,
        api_key: str,
        *,
        base_url: str | None = None,
        metadata: Any = None,
    ) -> None:
        self.calls.append(
            {
                "provider": provider,
                "api_key": api_key,
                "base_url": base_url,
                "metadata": metadata,
            }
        )


def test_update_provider_clears_api_key_when_null() -> None:
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
    result = asyncio.run(service.update_provider(user_id, "openai", payload))

    assert database.last_update == {
        "api_key_hash": None,
        "api_key_preview": None,
        "api_key_encrypted": None,
    }
    assert database.last_filters == {"user_id": str(user_id), "provider": "openai"}
    assert result.provider == "openai"
    assert result.api_key_preview is None
    assert result.has_api_key is False


def test_activate_provider_applies_backend_defaults(monkeypatch: pytest.MonkeyPatch) -> None:
    user_id = uuid4()
    database = _RecordingDatabase()
    settings = SimpleNamespace(encryption_key=Fernet.generate_key().decode("utf-8"))
    service = ProvidersService(settings, database, catalogue=Mock())
    validator = _RecordingValidator()
    service._validator = validator  # type: ignore[assignment]

    monkeypatch.setattr("app.services.provider_configs.hash_secret", lambda _: "hash", raising=False)
    monkeypatch.setattr("app.services.provider_configs.mask_secret", lambda _: "preview", raising=False)
    monkeypatch.setattr(
        "app.services.provider_configs.encrypt_secret",
        lambda secret, _settings: f"encrypted:{secret}",
        raising=False,
    )

    payload = ProviderActivationRequest(provider="groq", api_key="gsk_test_api_key_value")
    response = asyncio.run(service.activate_provider(user_id, payload))

    assert validator.calls, "Expected validator to be invoked"
    validator_call = validator.calls[0]
    assert validator_call["base_url"] == "https://api.groq.com/openai/v1"
    assert validator_call["metadata"] is None

    assert database.last_upsert is not None
    assert database.last_upsert["base_url"] == "https://api.groq.com/openai/v1"
    assert database.last_upsert["metadata"] == {}

    assert response.provider.base_url == "https://api.groq.com/openai/v1"

