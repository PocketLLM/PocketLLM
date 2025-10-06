"""Tests for provider configuration service helpers."""

from __future__ import annotations

from datetime import datetime, timezone
from types import SimpleNamespace
from typing import Any
from unittest.mock import AsyncMock, Mock
from uuid import UUID, uuid4

import pytest

pytest.importorskip("pydantic")

from cryptography.fernet import Fernet

from app.schemas.providers import ProviderActivationRequest, ProviderUpdateRequest
from app.services.provider_configs import ProvidersService
from app.services.providers import GroqProviderClient, OpenRouterProviderClient


@pytest.fixture
def anyio_backend() -> str:
    """Force AnyIO tests to run with asyncio only."""

    return "asyncio"


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


class _ActivationDatabaseStub:
    """Capture provider payloads written during activation."""

    def __init__(self) -> None:
        self.last_upsert: dict[str, Any] | None = None

    async def upsert(self, _table: str, data: dict[str, Any], *, on_conflict: str) -> list[dict[str, Any]]:
        self.last_upsert = data
        now = datetime.now(timezone.utc)
        user_id = UUID(data["user_id"])
        return [
            {
                "id": uuid4(),
                "user_id": user_id,
                "provider": data["provider"],
                "display_name": data.get("display_name"),
                "base_url": data.get("base_url"),
                "metadata": data.get("metadata"),
                "api_key_hash": data.get("api_key_hash"),
                "api_key_preview": data.get("api_key_preview"),
                "api_key_encrypted": data.get("api_key_encrypted"),
                "is_active": data.get("is_active", False),
                "created_at": now,
                "updated_at": now,
            }
        ]


@pytest.mark.anyio("asyncio")
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


@pytest.mark.anyio("asyncio")
async def test_activate_provider_applies_default_groq_configuration(monkeypatch) -> None:
    settings = SimpleNamespace(
        encryption_key=Fernet.generate_key().decode("utf-8"),
        openai_api_base=None,
        groq_api_base=None,
        openrouter_api_base=None,
        openrouter_app_url=None,
        openrouter_app_name=None,
    )
    database = _ActivationDatabaseStub()
    service = ProvidersService(settings, database, catalogue=Mock())
    monkeypatch.setattr("app.services.provider_configs.hash_secret", lambda value: "hash")
    monkeypatch.setattr("app.services.provider_configs.mask_secret", lambda value: "mask")
    validate_mock = AsyncMock(return_value=None)
    service._validator.validate = validate_mock  # type: ignore[assignment]

    payload = ProviderActivationRequest(provider="groq", api_key="gsk_" + "x" * 48)
    response = await service.activate_provider(uuid4(), payload)

    validate_mock.assert_awaited_once()
    assert validate_mock.await_args.kwargs["base_url"] == GroqProviderClient.default_base_url
    assert database.last_upsert is not None
    assert database.last_upsert["base_url"] == GroqProviderClient.default_base_url
    assert database.last_upsert["metadata"] == {}
    assert response.provider.base_url == GroqProviderClient.default_base_url


@pytest.mark.anyio("asyncio")
async def test_activate_provider_populates_openrouter_defaults(monkeypatch) -> None:
    settings = SimpleNamespace(
        encryption_key=Fernet.generate_key().decode("utf-8"),
        openai_api_base=None,
        groq_api_base=None,
        openrouter_api_base=None,
        openrouter_app_url="https://app.example",
        openrouter_app_name="PocketLLM",
    )
    database = _ActivationDatabaseStub()
    service = ProvidersService(settings, database, catalogue=Mock())
    monkeypatch.setattr("app.services.provider_configs.hash_secret", lambda value: "hash")
    monkeypatch.setattr("app.services.provider_configs.mask_secret", lambda value: "mask")
    validate_mock = AsyncMock(return_value=None)
    service._validator.validate = validate_mock  # type: ignore[assignment]

    payload = ProviderActivationRequest(provider="openrouter", api_key="ork_" + "y" * 48)
    await service.activate_provider(uuid4(), payload)

    validate_mock.assert_awaited_once()
    assert validate_mock.await_args.kwargs["base_url"] == OpenRouterProviderClient.default_base_url
    metadata = database.last_upsert["metadata"]
    assert metadata["http_referer"] == "https://app.example"
    assert metadata["x_title"] == "PocketLLM"
