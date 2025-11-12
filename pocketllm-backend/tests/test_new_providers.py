from __future__ import annotations

import asyncio
from types import SimpleNamespace
from typing import Any

import pytest

from app.schemas.providers import ProviderModel
from app.services.providers.anthropic import AnthropicProviderClient
from app.services.providers.catalogue import ProviderModelCatalogue
from app.services.providers.deepseek import DeepSeekProviderClient
from app.services.providers.mistral import MistralProviderClient


@pytest.fixture
def anyio_backend() -> str:
    return "asyncio"


class _AsyncModelListClient:
    def __init__(self, payload: Any, *, error: Exception | None = None) -> None:
        self._payload = payload
        self._error = error
        self.models = SimpleNamespace(list=self._list)
        self.closed = False

    async def _list(self) -> Any:
        if self._error:
            raise self._error
        await asyncio.sleep(0)
        return self._payload

    async def aclose(self) -> None:
        self.closed = True


class _SyncModelListClient:
    def __init__(self, payload: Any, *, error: Exception | None = None) -> None:
        self._payload = payload
        self._error = error
        self.models = SimpleNamespace(list=self._list)
        self.closed = False

    def _list(self) -> Any:
        if self._error:
            raise self._error
        return self._payload

    def close(self) -> None:
        self.closed = True


@pytest.mark.anyio
async def test_anthropic_client_parses_models() -> None:
    payload = {
        "data": [
            {
                "id": "claude-test",
                "display_name": "Claude Test",
                "description": "Test model",
                "context_window": 200000,
                "output_token_limit": 4096,
                "pricing": {"input": 0.001, "output": 0.002},
                "status": "active",
            }
        ]
    }
    settings = SimpleNamespace(anthropic_api_key=None, anthropic_api_base=None)
    client = AnthropicProviderClient(
        settings,
        api_key="key",
        client_factory=lambda **_: _AsyncModelListClient(payload),
    )

    models = await client.list_models()

    assert len(models) == 1
    model = models[0]
    assert isinstance(model, ProviderModel)
    assert model.provider == "anthropic"
    assert model.id == "claude-test"
    assert model.name == "Claude Test"
    assert model.context_window == 200000
    assert model.max_output_tokens == 4096
    assert model.pricing == {"input": 0.001, "output": 0.002}
    assert model.is_active is True


@pytest.mark.anyio
async def test_anthropic_client_handles_errors() -> None:
    settings = SimpleNamespace(anthropic_api_key=None, anthropic_api_base=None)
    client = AnthropicProviderClient(
        settings,
        api_key="key",
        client_factory=lambda **_: _AsyncModelListClient({}, error=RuntimeError("boom")),
    )

    models = await client.list_models()

    assert models == []


@pytest.mark.anyio
async def test_deepseek_client_inherits_openai_behaviour() -> None:
    payload = {"data": [{"id": "deepseek-chat", "object": "model"}]}
    settings = SimpleNamespace(deepseek_api_key=None, deepseek_api_base=None)

    recording: dict[str, Any] = {}

    def _factory(**kwargs: Any) -> _AsyncModelListClient:
        recording.update(kwargs)
        return _AsyncModelListClient(payload)

    client = DeepSeekProviderClient(settings, api_key="key", client_factory=_factory)

    models = await client.list_models()

    assert len(models) == 1
    assert models[0].provider == "deepseek"
    assert recording.get("base_url") == client.base_url


@pytest.mark.anyio
async def test_mistral_client_parses_models() -> None:
    payload = {
        "data": [
            {
                "id": "open-mistral-7b",
                "description": "General purpose model",
                "max_context_length": 32768,
                "aliases": ["mistral-7b"],
                "capabilities": {"completion_chat": True},
                "archived": False,
            }
        ]
    }
    settings = SimpleNamespace(mistral_api_key=None, mistral_api_base=None)

    stub = _SyncModelListClient(payload)
    client = MistralProviderClient(
        settings,
        api_key="key",
        client_factory=lambda **_: stub,
    )

    models = await client.list_models()

    assert len(models) == 1
    model = models[0]
    assert model.provider == "mistral"
    assert model.id == "open-mistral-7b"
    assert model.context_window == 32768
    assert model.is_active is True
    assert stub.closed is True


@pytest.mark.anyio
async def test_mistral_client_handles_errors() -> None:
    settings = SimpleNamespace(mistral_api_key=None, mistral_api_base=None)
    stub = _SyncModelListClient({}, error=RuntimeError("failure"))
    client = MistralProviderClient(
        settings,
        api_key="key",
        client_factory=lambda **_: stub,
    )

    models = await client.list_models()

    assert models == []
    assert stub.closed is True


def test_catalogue_fallback_includes_new_providers() -> None:
    settings = SimpleNamespace(
        provider_catalogue_cache_ttl=0,
        provider_catalogue_provider_timeout=10.0,
        provider_catalogue_total_timeout=20.0,
        openai_api_key=None,
        openai_api_base=None,
        groq_api_key=None,
        groq_api_base=None,
        openrouter_api_key=None,
        openrouter_api_base=None,
        openrouter_app_url=None,
        openrouter_app_name=None,
        imagerouter_api_key=None,
        imagerouter_api_base=None,
        anthropic_api_key="anthropic-key",
        anthropic_api_base="https://api.anthropic.com",
        deepseek_api_key="deepseek-key",
        deepseek_api_base="https://api.deepseek.com",
        mistral_api_key="mistral-key",
        mistral_api_base="https://api.mistral.ai",
    )

    catalogue = ProviderModelCatalogue(settings)
    fallbacks = catalogue._build_fallback_configs()

    assert "anthropic" in fallbacks
    assert fallbacks["anthropic"].api_key == "anthropic-key"
    assert fallbacks["anthropic"].base_url == "https://api.anthropic.com"

    assert "deepseek" in fallbacks
    assert fallbacks["deepseek"].api_key == "deepseek-key"
    assert fallbacks["deepseek"].base_url == "https://api.deepseek.com"

    assert "mistral" in fallbacks
    assert fallbacks["mistral"].api_key == "mistral-key"
    assert fallbacks["mistral"].base_url == "https://api.mistral.ai"
